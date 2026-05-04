/**
 * SWE-bench Scraper
 * Scrapes code fixing benchmarks from swebench.com
 */

import { BaseScraper } from './base.js';
import { getBrowserManager } from '../utils/browser.js';

export class SWEBenchScraper extends BaseScraper {
  constructor(options = {}) {
    super(options);
    this.baseUrl = 'https://swebench.com';
  }

  /**
   * Scrape SWE-bench leaderboard
   */
  async scrape(options = {}) {
    this.log('Starting SWE-bench scrape...');

    try {
      // Try multiple methods
      const data = await this._scrapeWithBrowser();

      if (!data || data.length === 0) {
        // Fallback to direct API
        return await this._scrapeFromAPI();
      }

      return {
        source: 'swebench',
        fetchedAt: new Date().toISOString(),
        models: this._normalizeModels(data)
      };
    } catch (error) {
      this.error('Failed to scrape SWE-bench', error);
      return {
        source: 'swebench',
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

        // Method 1: Find JSON data in script tags
        const scripts = document.querySelectorAll('script[type="application/json"]');
        scripts.forEach(script => {
          try {
            const data = JSON.parse(script.textContent);
            if (data.models || data.leaderboard || data.results) {
              return data;
            }
          } catch (e) {
            // Continue
          }
        });

        // Method 2: Look for table rows
        const tableRows = document.querySelectorAll('table tbody tr, .leaderboard-row, [class*="model"]');
        tableRows.forEach(row => {
          const cells = row.querySelectorAll('td, [class*="cell"]');
          if (cells.length >= 3) {
            results.push({
              modelName: cells[0]?.textContent?.trim() || '',
              passRate: cells[1]?.textContent?.trim() || '',
              cost: cells[2]?.textContent?.trim() || ''
            });
          }
        });

        // Method 3: Look for cards or specific elements
        if (results.length === 0) {
          const cards = document.querySelectorAll('[class*="card"], [class*="entry"], [class*="result"]');
          cards.forEach(card => {
            const name = card.querySelector('[class*="name"], [class*="model"]');
            const score = card.querySelector('[class*="rate"], [class*="score"], [class*="pass"]');
            if (name) {
              results.push({
                modelName: name.textContent?.trim() || '',
                passRate: score?.textContent?.trim() || ''
              });
            }
          });
        }

        return results;
      },
      { waitForSelector: 'table', timeout: 20000 }
    );

    return data;
  }

  async _scrapeFromAPI() {
    // Try common API patterns
    const apiUrls = [
      'https://swebench.com/api/leaderboard',
      'https://swebench.com/api/models',
      'https://swebench.com/leaderboard.json'
    ];

    for (const url of apiUrls) {
      try {
        const data = await this.fetch(url);
        if (data && (Array.isArray(data) || data.models || data.results)) {
          return Array.isArray(data) ? data : (data.models || data.results);
        }
      } catch (e) {
        // Try next URL
      }
    }

    return [];
  }

  _normalizeModels(data) {
    if (!data) return [];

    const models = Array.isArray(data) ? data : [];

    return models.map((item, index) => ({
      rank: index + 1,
      modelName: item.modelName || item.name || item.model || '',
      passRate: item.passRate || item.pass_rate || item.resolved || 'N/A',
      averageCost: item.averageCost || item.cost || item.avg_cost || 'N/A',
      instanceCount: item.instanceCount || item.instances || 'N/A',
      developer: item.developer || item.vendor || '',
      date: item.date || item.submitted_at || '',
      metadata: item
    }));
  }
}

export default SWEBenchScraper;