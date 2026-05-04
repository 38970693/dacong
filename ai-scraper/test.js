/**
 * Quick test script
 * Run: node test.js
 */

import { AIModelScraper } from './src/index.js';

async function test() {
  console.log('Testing AI Model Scraper...\n');

  const scraper = new AIModelScraper({
    output: { dir: './data' },
    browser: { headless: true }
  });

  try {
    // Test LMArena
    console.log('=== Testing LMArena ===');
    const lmarena = await scraper.scrape('lmarena', { category: 'text', useBrowser: true });
    console.log(`Categories found: ${lmarena.categories?.length || 0}`);
    if (lmarena.categories?.[0]?.models?.length > 0) {
      console.log(`First category models: ${lmarena.categories[0].models.length}`);
      console.log('Sample:', JSON.stringify(lmarena.categories[0].models[0], null, 2));
    } else {
      console.log('Raw data:', JSON.stringify(lmarena, null, 2));
    }

    // Export to JSON
    console.log('\n=== Exporting to JSON ===');
    const path = await scraper.export(lmarena, { format: 'json', prefix: 'test-lmarena' });
    console.log(`Exported to: ${path}`);

    // Export to CSV
    console.log('\n=== Exporting to CSV ===');
    const csvPath = await scraper.export(lmarena, { format: 'csv', prefix: 'test-lmarena' });
    console.log(`Exported to: ${csvPath}`);

  } catch (error) {
    console.error('Error:', error.message);
    console.error(error.stack);
  } finally {
    // Cleanup
    const { closeBrowser } = await import('./src/utils/browser.js');
    await closeBrowser();
    process.exit(0);
  }
}

test();