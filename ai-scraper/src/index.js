/**
 * AI Model Leaderboard Scraper
 * Main entry point
 */

import { Command } from 'commander';
import winston from 'winston';
import { createConfig } from './config.js';
import { closeBrowser } from './utils/browser.js';
import { Exporter } from './utils/exporter.js';
import { LMArenaScraper } from './scrapers/lmarena.js';
import { SWEBenchScraper } from './scrapers/swebench.js';
import { ArtificialAnalysisScraper } from './scrapers/artificial-analysis.js';
import { AIPingScraper } from './scrapers/aiping.js';

// Logger setup
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.printf(({ level, message, timestamp, ...data }) => {
      const dataStr = Object.keys(data).length ? ` ${JSON.stringify(data)}` : '';
      return `${timestamp} [${level.toUpperCase()}] ${message}${dataStr}`;
    })
  ),
  transports: [
    new winston.transports.Console()
  ]
});

/**
 * Main scraper class
 */
class AIModelScraper {
  constructor(options = {}) {
    this.config = createConfig(options);
    this.logger = logger;
    this.exporter = new Exporter({ outputDir: this.config.output.dir });

    this.scrapers = {
      lmarena: new LMArenaScraper({ logger, ...options }),
      swebench: new SWEBenchScraper({ logger, ...options }),
      'artificial-analysis': new ArtificialAnalysisScraper({ logger, ...options }),
      aiping: new AIPingScraper({ logger, ...options })
    };
  }

  /**
   * Scrape all sources
   */
  async scrapeAll(options = {}) {
    this.logger.info('Starting scrape for all sources...');

    const results = await Promise.allSettled(
      Object.entries(this.scrapers).map(([name, scraper]) =>
        scraper.scrape(options).then(data => ({ name, data }))
      )
    );

    const success = [];
    const failed = [];

    results.forEach(result => {
      if (result.status === 'fulfilled') {
        success.push(result.value);
      } else {
        failed.push({ error: result.reason.message });
      }
    });

    return {
      fetchedAt: new Date().toISOString(),
      sources: success,
      failedSources: failed,
      totalSources: Object.keys(this.scrapers).length,
      successCount: success.length,
      failedCount: failed.length
    };
  }

  /**
   * Scrape specific source
   */
  async scrape(sourceName, options = {}) {
    const scraper = this.scrapers[sourceName];
    if (!scraper) {
      throw new Error(`Unknown source: ${sourceName}. Available: ${Object.keys(this.scrapers).join(', ')}`);
    }

    this.logger.info(`Scraping ${sourceName}...`);
    return scraper.scrape(options);
  }

  /**
   * Export data to file
   */
  async export(data, options = {}) {
    const { format = 'json', path, prefix = 'leaderboard' } = options;

    if (path) {
      // Custom path
      this.exporter.outputDir = path;
    }

    switch (format) {
      case 'json':
        return this.exporter.toJSON(data, `${prefix}.json`);
      case 'csv':
        return this.exporter.toCSV(data, `${prefix}.csv`);
      case 'markdown':
        return this.exporter.toMarkdown(data, `${prefix}.md`);
      case 'all':
        return this.exporter.toAll(data, prefix);
      default:
        throw new Error(`Unknown format: ${format}`);
    }
  }

  /**
   * Run and export
   */
  async run(source = 'all', options = {}) {
    try {
      let data;

      if (source === 'all') {
        data = await this.scrapeAll(options);
      } else {
        const result = await this.scrape(source, options);
        data = {
          fetchedAt: new Date().toISOString(),
          sources: [{ name: source, data: result }]
        };
      }

      // Export
      const exportOptions = {
        format: options.format || this.config.output.format,
        prefix: options.prefix || source
      };

      const exportResults = await this.export(data, exportOptions);

      this.logger.info('Export complete', exportResults);
      return { data, exportResults };

    } finally {
      // Cleanup browser
      await closeBrowser();
    }
  }
}

// CLI entry point
async function main() {
  const program = new Command();

  program
    .name('ai-model-scraper')
    .description('Scrape AI model leaderboards from multiple sources')
    .version('1.0.0');

  program
    .argument('[source]', 'Source to scrape: all, lmarena, swebench, artificial-analysis, aiping', 'all')
    .option('-o, --output <dir>', 'Output directory', './data')
    .option('-f, --format <format>', 'Export format: json, csv, markdown, all', 'all')
    .option('-p, --proxy <url>', 'Proxy URL (http://host:port)')
    .option('--headless', 'Run browser in headless mode', true)
    .option('--no-headless', 'Run browser with visible window')
    .option('-v, --verbose', 'Verbose logging')
    .action(async (source, options) => {
      if (options.verbose) {
        logger.level = 'debug';
      }

      // Parse proxy
      let proxyConfig = null;
      if (options.proxy) {
        const url = new URL(options.proxy);
        proxyConfig = {
          host: url.hostname,
          port: parseInt(url.port),
          protocol: url.protocol.replace(':', '')
        };
        if (url.username && url.password) {
          proxyConfig.auth = {
            username: url.username,
            password: url.password
          };
        }
      }

      const scraper = new AIModelScraper({
        output: { dir: options.output },
        proxy: proxyConfig,
        browser: { headless: options.headless }
      });

      try {
        const { data, exportResults } = await scraper.run(source, {
          format: options.format
        });

        console.log('\n=== Scrape Complete ===');
        console.log(`Sources: ${data.successCount}/${data.totalSources} succeeded`);

        if (data.failedCount > 0) {
          console.log(`Failed: ${data.failedCount}`);
          data.failedSources.forEach(f => console.log(`  - ${f.error}`));
        }

        console.log('\nExports:');
        Object.entries(exportResults).forEach(([format, path]) => {
          if (path) console.log(`  ${format}: ${path}`);
        });

      } catch (error) {
        logger.error('Fatal error', error);
        process.exit(1);
      }
    });

  await program.parseAsync(process.argv);
}

// Export for use as library
export { AIModelScraper };
export default AIModelScraper;

// Run if called directly
main().catch(console.error);