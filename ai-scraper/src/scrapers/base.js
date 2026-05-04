/**
 * Base Scraper Class
 * Provides common functionality for all scrapers
 */

import axios from 'axios';
import * as cheerio from 'cheerio';
import { config } from '../config.js';

export class BaseScraper {
  constructor(options = {}) {
    this.config = { ...config, ...options };
    this.logger = options.logger || console;
    this.sourceName = this.constructor.name;
  }

  /**
   * Make HTTP request with retry logic
   */
  async fetch(url, options = {}) {
    const {
      retries = this.config.request.retries,
      method = 'GET',
      headers = {},
      data = null
    } = options;

    let lastError;
    let currentDelay = this.config.request.retryDelay;

    for (let attempt = 0; attempt <= retries; attempt++) {
      try {
        const response = await this._makeRequest(url, {
          method,
          headers,
          data,
          attempt
        });
        return response;
      } catch (error) {
        lastError = error;
        this.logger.warn(`Attempt ${attempt + 1} failed for ${url}: ${error.message}`);

        if (attempt < retries) {
          await this._sleep(currentDelay);
          currentDelay = Math.min(
            currentDelay * this.config.request.backoffMultiplier,
            this.config.request.maxRetryDelay
          );
        }
      }
    }

    throw new Error(`Failed to fetch ${url} after ${retries + 1} attempts: ${lastError.message}`);
  }

  async _makeRequest(url, options = {}) {
    const { method, headers, data, attempt } = options;

    const requestConfig = {
      method,
      url,
      headers: {
        'User-Agent': this.config.request.userAgent,
        ...headers
      },
      timeout: this.config.request.timeout,
      ...(data && { data })
    };

    // Add proxy if configured
    if (this.config.proxy) {
      requestConfig.proxy = this.config.proxy;
    }

    const response = await axios(requestConfig);
    return response.data;
  }

  /**
   * Sleep utility
   */
  async _sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * Random delay for rate limiting
   */
  async _randomDelay() {
    const delay = Math.floor(
      Math.random() * (this.config.rateLimit.maxDelay - this.config.rateLimit.minDelay) +
      this.config.rateLimit.minDelay
    );
    await this._sleep(delay);
  }

  /**
   * Log info message
   */
  log(message, data = {}) {
    this.logger.info(`[${this.sourceName}] ${message}`, data);
  }

  /**
   * Log error
   */
  error(message, error = null) {
    this.logger.error(`[${this.sourceName}] ${message}`, { error: error?.message, stack: error?.stack });
  }

  /**
   * Parse HTML with cheerio
   */
  parseHTML(html) {
    return cheerio.load(html);
  }

  /**
   * Extract text from element
   */
  getText($, element, selector) {
    const el = $(selector, element);
    return el.text().trim();
  }

  /**
   * Main scrape method - to be implemented by subclasses
   */
  async scrape(options = {}) {
    throw new Error('scrape() must be implemented by subclass');
  }
}

export default BaseScraper;