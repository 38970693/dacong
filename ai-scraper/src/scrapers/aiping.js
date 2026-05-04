/**
 * AI Ping Scraper
 * Scrapes model ratings from aiping.dev
 */

import { BaseScraper } from './base.js';
import { getBrowserManager } from '../utils/browser.js';

export class AIPingScraper extends BaseScraper {
  constructor(options = {}) {
    super(options);
    this.baseUrl = 'https://aiping.dev';
  }

  /**
   * Scrape AI Ping leaderboard
   */
  async scrape(options = {}) {
    this.log('Starting AI Ping scrape...');

    try {
      const data = await this._scrapeWithBrowser();

      return {
        source: 'aiping',
        fetchedAt: new Date().toISOString(),
        models: this._normalizeModels(data)
      };
    } catch (error) {
      this.error('Failed to scrape AI Ping', error);
      return {
        source: 'aiping',
        fetchedAt: new Date().toISOString(),
        models: [],
        error: error.message
      };
    }
  }

  async _scrapeWithBrowser() {
    const browser = getBrowserManager();

    const data = await browser.evaluate(
      this.baseUrl,
      () => {
        const results = [];

        // Look for JSON data
        const scripts = document.querySelectorAll('script[type="application/json"]');
        for (const script of scripts) {
          try {
            const parsed = JSON.parse(script.textContent);
            if (parsed.models || parsed.results || parsed.data) {
              return parsed;
            }
          } catch (e) {
            // Continue
          }
        }

        // Table rows
        const tableRows = document.querySelectorAll('table tbody tr');
        tableRows.forEach(row => {
          const cells = row.querySelectorAll('td');
          if (cells.length >= 3) {
            results.push({
              modelName: cells[0]?.textContent?.trim() || '',
              rating: cells[1]?.textContent?.trim() || '',
              vendor: cells[2]?.textContent?.trim() || ''
            });
          }
        });

        // Cards
        if (results.length === 0) {
          const cards = document.querySelectorAll('[class*="card"], [class*="model"]');
          cards.forEach(card => {
            const name = card.querySelector('[class*="name"]')?.textContent?.trim();
            const rating = card.querySelector('[class*="rating"]')?.textContent?.trim();
            if (name) {
              results.push({ modelName: name, rating: rating || 'N/A' });
            }
          });
        }

        return results;
      },
      { waitForSelector: 'table', timeout: 15000 }
    );

    return data;
  }

  _normalizeModels(data) {
    if (!data) return [];

    const models = Array.isArray(data) ? data : (data.models || data.results || data.data || []);

    return models.map((item, index) => ({
      rank: index + 1,
      modelName: item.modelName || item.name || '',
      rating: item.rating || item.score || 'N/A',
      vendor: item.vendor || item.developer || '',
      categories: item.categories || [],
      metadata: item
    }));
  }
}

export default AIPingScraper;