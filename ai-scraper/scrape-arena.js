/**
 * Arena.ai Scraper with Proxy
 * Directly scrape arena.ai leaderboard
 */

import axios from 'axios';
import * as cheerio from 'cheerio';

const PROXY = 'http://127.0.0.1:7890';
const USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

async function scrapeArena(path) {
  const url = `https://arena.ai${path}`;
  console.log(`Fetching: ${url}`);

  try {
    const response = await axios.get(url, {
      proxy: {
        host: '127.0.0.1',
        port: 7890,
        protocol: 'http'
      },
      headers: {
        'User-Agent': USER_AGENT,
        'Accept': 'text/html,application/xhtml+xml',
        'Accept-Language': 'en-US,en;q=0.9'
      },
      timeout: 30000,
      maxRedirects: 5
    });

    return response.data;
  } catch (error) {
    console.error(`Error fetching ${url}: ${error.message}`);
    return null;
  }
}

function parseArenaData(html) {
  const $ = cheerio.load(html);
  const models = [];

  // Try to find leaderboard data
  // Method 1: Look for JSON data in script tags
  $('script[type="application/json"]').each((i, el) => {
    try {
      const data = JSON.parse($(el).html());
      console.log('Found JSON data, keys:', Object.keys(data));
    } catch (e) {
      // Not JSON
    }
  });

  // Method 2: Look for table rows
  $('table tbody tr, tbody tr').each((i, row) => {
    const cells = $(row).find('td');
    if (cells.length >= 3) {
      models.push({
        rank: $(cells[0]).text().trim(),
        model: $(cells[1]).text().trim(),
        score: $(cells[2]).text().trim()
      });
    }
  });

  // Method 3: Look for div patterns
  $('[class*="model"], [class*="rank"], [class*="elo"]').each((i, el) => {
    const text = $(el).text().trim();
    if (text && text.length < 100) {
      console.log(`Found: ${text}`);
    }
  });

  return models;
}

async function main() {
  console.log('=== Arena.ai Scraper ===\n');

  // Test 1: Try to find API
  const paths = [
    '/leaderboard/code',
    '/leaderboard/text',
    '/api/leaderboard'
  ];

  for (const path of paths) {
    console.log(`\n--- Testing ${path} ---`);
    const html = await scrapeArena(path);
    if (html) {
      const $ = cheerio.load(html);
      console.log(`Page loaded, length: ${html.length}`);

      // Look for model names
      const modelElements = $('[class*="name"], [class*="model"], [class*="title"]');
      console.log(`Found ${modelElements.length} model-related elements`);

      // Look for scores/ELO
      const scoreElements = $('[class*="score"], [class*="elo"], [class*="rating"]');
      console.log(`Found ${scoreElements.length} score-related elements`);

      // Look for table
      const tables = $('table');
      console.log(`Found ${tables.length} tables`);

      if (tables.length > 0) {
        tables.find('tbody tr').each((i, row) => {
          const cells = $(row).find('td');
          if (cells.length > 0) {
            const rowData = cells.map((j, cell) => $(cell).text().trim()).get().join(' | ');
            if (rowData) console.log(`Row ${i}: ${rowData}`);
            if (i > 20) return false;
          }
        });
      }
    }
  }

  // Test 2: Try to access LMArena redirect
  console.log('\n--- Testing LMArena redirect ---');
  const lmarenaHtml = await scrapeArena('/');
  if (lmarenaHtml) {
    console.log(`LMArena page loaded, redirect target found`);
  }
}

main().catch(console.error);