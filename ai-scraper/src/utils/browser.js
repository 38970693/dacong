/**
 * Browser Manager
 * Handles Puppeteer browser instance for JavaScript-rendered content
 */

import puppeteer from 'puppeteer';
import { config } from '../config.js';

class BrowserManager {
  constructor() {
    this.browser = null;
    this.config = config;
  }

  async launch() {
    if (this.browser) {
      return this.browser;
    }

    this.browser = await puppeteer.launch({
      headless: this.config.browser.headless,
      args: this.config.browser.args,
      timeout: this.config.browser.timeout
    });

    return this.browser;
  }

  async getBrowser() {
    if (!this.browser) {
      await this.launch();
    }
    return this.browser;
  }

  async close() {
    if (this.browser) {
      await this.browser.close();
      this.browser = null;
    }
  }

  /**
   * Navigate to URL and wait for content
   */
  async navigate(url, options = {}) {
    const browser = await this.getBrowser();
    const page = await browser.newPage();

    // Set viewport
    await page.setViewport({ width: 1920, height: 1080 });

    // Set extra headers
    await page.setExtraHTTPHeaders({
      'Accept-Language': 'en-US,en;q=0.9',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
    });

    // Apply proxy if configured
    if (this.config.proxy) {
      // Use default proxy settings for Puppeteer
      // Puppeteer will use system proxy settings
    }

    // Navigate with retry
    let lastError;
    for (let attempt = 0; attempt <= this.config.request.retries; attempt++) {
      try {
        await page.goto(url, {
          waitUntil: options.waitUntil || 'networkidle2',
          timeout: options.timeout || this.config.browser.timeout
        });
        break;
      } catch (error) {
        lastError = error;
        this.log(`Navigation attempt ${attempt + 1} failed: ${error.message}`);

        if (attempt < this.config.request.retries) {
          await this._sleep(this.config.request.retryDelay * Math.pow(2, attempt));
        }
      }
    }

    if (lastError) {
      throw lastError;
    }

    // Wait for specific selector if provided
    if (options.waitForSelector) {
      await page.waitForSelector(options.waitForSelector, {
        timeout: options.selectorTimeout || 10000
      }).catch(() => {
        this.log(`Selector ${options.waitForSelector} not found, continuing...`);
      });
    }

    // Execute additional wait if provided
    if (options.waitFunction) {
      await page.waitForFunction(options.waitFunction);
    }

    return page;
  }

  /**
   * Get page content as HTML
   */
  async getPageContent(url, options = {}) {
    const page = await this.navigate(url, options);
    const content = await page.content();
    await page.close();
    return content;
  }

  /**
   * Evaluate JavaScript on page
   */
  async evaluate(url, fn, options = {}) {
    const page = await this.navigate(url, options);
    const result = await page.evaluate(fn);
    await page.close();
    return result;
  }

  async _sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  log(message, ...args) {
    console.log(`[BrowserManager] ${message}`, ...args);
  }
}

// Singleton instance
let browserManager = null;

export function getBrowserManager() {
  if (!browserManager) {
    browserManager = new BrowserManager();
  }
  return browserManager;
}

export async function closeBrowser() {
  if (browserManager) {
    await browserManager.close();
  }
}

export default BrowserManager;