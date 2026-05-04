/**
 * Artificial Analysis Scraper
 * Scrapes model benchmarks from artificialanalysis.ai
 */

import { BaseScraper } from './base.js';
import { getBrowserManager } from '../utils/browser.js';

export class ArtificialAnalysisScraper extends BaseScraper {
  constructor(options = {}) {
    super(options);
    this.baseUrl = 'https://artificialanalysis.ai';
  }

  /**
   * Scrape Artificial Analysis leaderboard
   */
  async scrape(options = {}) {
    this.log('Starting Artificial Analysis scrape...');

    try {
      const data = await this._scrapeWithBrowser();

      return {
        source: 'artificial-analysis',
        fetchedAt: new Date().toISOString(),
        models: this._normalizeModels(data)
      };
    } catch (error) {
      this.error('Failed to scrape Artificial Analysis', error);
      return {
        source: 'artificial-analysis',
        fetchedAt: new Date().toISOString(),
        models: [],
        error: error.message
      };
    }
  }

  async _scrapeWithBrowser() {
    const browser = getBrowserManager();

    const data = await browser.evaluate(
      `${this.baseUrl}/models`,
      () => {
        const results = [];

        // Method 1: Look for JSON data
        const scripts = document.querySelectorAll('script[id="__NEXT_DATA__"], script[type="application/json"]');
        for (const script of scripts) {
          try {
            const parsed = JSON.parse(script.textContent);
            if (parsed.props?.pageProps?.models || parsed.props?.pageProps?.data) {
              return { source: 'next-data', data: parsed.props.pageProps };
            }
          } catch (e) {
            // Continue
          }
        }

        // Method 2: Table rows
        const tableRows = document.querySelectorAll('table tbody tr');
        tableRows.forEach(row => {
          const cells = row.querySelectorAll('td');
          if (cells.length >= 5) {
            results.push({
              modelName: cells[0]?.textContent?.trim() || '',
              mmlu: cells[1]?.textContent?.trim() || '',
              math: cells[2]?.textContent?.trim() || '',
              humaneval: cells[3]?.textContent?.trim() || '',
              price: cells[4]?.textContent?.trim() || ''
            });
          }
        });

        // Method 3: Cards or list items
        if (results.length === 0) {
          const items = document.querySelectorAll('[class*="model-card"], [class*="result-item"], tbody tr');
          items.forEach(item => {
            const name = item.querySelector('[class*="name"], th')?.textContent?.trim();
            const value = item.querySelector('[class*="value"], td')?.textContent?.trim();
            if (name) {
              results.push({ modelName: name, data: value });
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

    // Handle next-data structure
    if (data.source === 'next-data' && data.data) {
      const models = data.data.models || data.data.data || [];
      return models.map((item, index) => ({
        rank: index + 1,
        modelName: item.name || item.modelName || '',
        mmlu: item.mmlu || item.MMLU || 'N/A',
        math: item.math || item.MATH || 'N/A',
        humaneval: item.humaneval || item.HumanEval || 'N/A',
        price: item.price || item.pricePerM || 'N/A',
        contextWindow: item.contextWindow || item.context || 'N/A',
        developer: item.developer || item.vendor || '',
        metadata: item
      }));
    }

    // Handle flat array
    if (Array.isArray(data)) {
      return data.map((item, index) => ({
        rank: index + 1,
        modelName: item.modelName || item.name || '',
        mmlu: item.mmlu || 'N/A',
        math: item.math || 'N/A',
        humaneval: item.humaneval || 'N/A',
        price: item.price || 'N/A',
        metadata: item
      }));
    }

    return [];
  }
}

export default ArtificialAnalysisScraper;