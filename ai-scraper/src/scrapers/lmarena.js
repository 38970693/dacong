/**
 * LMArena Scraper
 * Scrapes rankings from lmarena.ai (Text Arena, WebDev Arena, Vision Arena, etc.)
 * Uses lmarenaai.cn as fallback due to bot protection on original site
 */

import { BaseScraper } from './base.js';
import { getBrowserManager } from '../utils/browser.js';

export class LMArenaScraper extends BaseScraper {
  constructor(options = {}) {
    super(options);
    // Primary site may have bot protection, use mirror as fallback
    this.sources = [
      { id: 'text', name: 'Text Arena', path: '/' },
      { id: 'webdev', name: 'WebDev Arena', path: '/?webdev' },
      { id: 'vision', name: 'Vision Arena', path: '/?vision' },
      { id: 'text-to-image', name: 'Text-to-Image', path: '/?text-to-image' },
      { id: 'image-edit', name: 'Image Edit', path: '/?image-edit' },
      { id: 'search', name: 'Search Arena', path: '/?search' },
      { id: 'text-to-video', name: 'Text-to-Video', path: '/?text-to-video' },
      { id: 'image-to-video', name: 'Image-to-Video', path: '/?image-to-video' },
      { id: 'copilot', name: 'Copilot Arena', path: '/?copilot' }
    ];

    // Sites to try in order
    this.sites = [
      { name: 'lmarenaai.cn', baseUrl: 'https://lmarenaai.cn' },  // Chinese mirror, more accessible
      { name: 'lmarena.ai', baseUrl: 'https://lmarena.ai' }        // Original, may have bot protection
    ];
  }

  /**
   * Scrape leaderboard data
   * @param {Object} options - { category: 'text' | 'webdev' | 'all', useBrowser: boolean }
   */
  async scrape(options = {}) {
    const { category = 'all' } = options;
    const sources = category === 'all'
      ? this.sources
      : this.sources.filter(s => s.id === category);

    this.log(`Starting scrape for category: ${category}, sources: ${sources.length}`);

    const results = await Promise.all(
      sources.map(source => this._scrapeSource(source))
    );

    return {
      source: 'lmarena',
      fetchedAt: new Date().toISOString(),
      categories: results.filter(r => r.models.length > 0)
    };
  }

  async _scrapeSource(source) {
    this.log(`Scraping ${source.name}...`);

    // Try each site until one works
    for (const site of this.sites) {
      try {
        const result = await this._fetchFromSite(site, source);
        if (result.models.length > 0) {
          this.log(`Successfully scraped ${source.name} from ${site.name}`);
          return result;
        }
      } catch (error) {
        this.log(`Failed ${site.name}: ${error.message}`);
      }
    }

    // All sites failed
    return {
      category: source.id,
      categoryName: source.name,
      models: [],
      error: 'All sources failed'
    };
  }

  async _fetchFromSite(site, source) {
    const html = await this.fetch(`${site.baseUrl}${source.path}`);
    return this._parseHTMLData(html, source);
  }

  _parseHTMLData(html, source) {
    const $ = this.parseHTML(html);
    const models = [];

    // Try to find table
    $('table.leaderboard-table tbody tr').each((i, row) => {
      const cells = $(row).find('td');
      if (cells.length >= 5) {
        models.push({
          rank: $(cells[0]).text().trim(),
          modelName: $(cells[1]).text().trim(),
          score: $(cells[2]).text().trim(),
          confidence: $(cells[3]).text().trim(),
          votes: $(cells[4]).text().trim(),
          developer: cells[5] ? $(cells[5]).text().trim() : '',
          license: cells[6] ? $(cells[6]).text().trim() : ''
        });
      }
    });

    // Fallback: look for any table
    if (models.length === 0) {
      $('table tbody tr').each((i, row) => {
        const cells = $(row).find('td');
        if (cells.length >= 3) {
          models.push({
            rank: $(cells[0]).text().trim(),
            modelName: $(cells[1]).text().trim(),
            score: $(cells[2]).text().trim()
          });
        }
      });
    }

    return {
      category: source.id,
      categoryName: source.name,
      models,
      scrapedAt: new Date().toISOString()
    };
  }
}

export default LMArenaScraper;