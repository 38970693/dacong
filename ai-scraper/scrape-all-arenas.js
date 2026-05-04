/**
 * Scrape ALL Arena.ai categories
 * Code, Text, Vision, Document, Image, Video, etc.
 */

import axios from 'axios';
import * as cheerio from 'cheerio';
import fs from 'fs';

const PROXY = { host: '127.0.0.1', port: 7890, protocol: 'http' };
const HEADERS = { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0' };

async function scrapeArena(category) {
  const url = `https://arena.ai/leaderboard/${category}`;
  console.log(`Fetching ${url}...`);

  try {
    const response = await axios.get(url, {
      proxy: PROXY,
      headers: HEADERS,
      timeout: 25000
    });

    const $ = cheerio.load(response.data);
    const models = [];

    $('table tbody tr').each((i, row) => {
      const cells = $(row).find('td');
      if (cells.length >= 4) {
        const modelText = $(cells[2]).text().trim().replace(/\s+/g, ' ');
        // Parse company from model name
        const companyMatch = modelText.match(/(Anthropic|OpenAI|Google|xAI|Meta|DeepSeek|Moonshot|Alibaba|Baidu|Z\.ai|Xiaomi)/);
        const company = companyMatch ? companyMatch[1] : 'Other';

        models.push({
          rank: parseInt($(cells[0]).text().trim()) || i + 1,
          idx: $(cells[1]).text().trim(),
          model: modelText,
          company,
          elo: $(cells[3]).text().trim(),
          votes: $(cells[4])?.text().trim() || 'N/A',
          price: $(cells[5])?.text().trim() || 'N/A',
          context: $(cells[6])?.text().trim() || 'N/A'
        });
      }
    });

    return models;
  } catch (error) {
    console.error(`Error fetching ${category}: ${error.message}`);
    return [];
  }
}

function exportToMarkdown(allData) {
  const categories = Object.keys(allData);

  let md = `# AI Model Rankings by Category\n`;
  md += `> Data source: arena.ai | Updated: ${new Date().toISOString().split('T')[0]}\n\n`;
  md += `## Categories: ${categories.length}\n\n`;
  md += `| Category | Models |\n`;
  md += `|----------|-------:|\n`;
  categories.forEach(cat => {
    md += `| ${cat} | ${allData[cat].length} |\n`;
  });
  md += `\n---\n\n`;

  // Category mapping for better names
  const catNames = {
    'code': '🏆 Code Arena',
    'text': '📝 Text Arena',
    'vision': '👁️ Vision Arena',
    'document': '📄 Document Arena',
    'image-edit': '🖼️ Image Edit Arena',
    'text-to-image': '🎨 Text-to-Image Arena',
    'image-to-video': '🎬 Image-to-Video Arena',
    'text-to-video': '🎥 Text-to-Video Arena',
    'video-edit': '✂️ Video Edit Arena',
    'search': '🔍 Search Arena'
  };

  for (const cat of categories) {
    const models = allData[cat];
    if (models.length === 0) continue;

    md += `## ${catNames[cat] || cat}\n\n`;
    md += `| Rank | Model | Company | ELO | Votes | Price |\n`;
    md += `|:---:|------|---------|:---:|-----:|------|\n`;

    models.slice(0, 15).forEach(m => {
      md += `| ${m.rank} | ${m.model} | ${m.company} | ${m.elo} | ${m.votes} | ${m.price} |\n`;
    });
    md += `\n---\n\n`;
  }

  return md;
}

async function main() {
  const categories = ['code', 'text', 'vision', 'document', 'image-edit', 'text-to-image', 'image-to-video', 'text-to-video', 'video-edit'];

  const allData = {};
  for (const cat of categories) {
    allData[cat] = await scrapeArena(cat);
    // Small delay between requests
    await new Promise(r => setTimeout(r, 500));
  }

  // Export Markdown
  const markdown = exportToMarkdown(allData);
  const outputDir = 'data/rankings';
  if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir, { recursive: true });

  fs.writeFileSync(`${outputDir}/rankings-by-category.md`, markdown, 'utf8');
  console.log('✓ Exported: rankings-by-category.md');

  // Export JSON
  fs.writeFileSync(`${outputDir}/rankings-all.json`, JSON.stringify(allData, null, 2), 'utf8');
  console.log('✓ Exported: rankings-all.json');

  // Print summary
  console.log('\n=== Summary ===');
  for (const [cat, models] of Object.entries(allData)) {
    console.log(`${cat}: ${models.length} models`);
    if (models.length > 0) {
      console.log(`  Top: ${models[0].model} (ELO: ${models[0].elo})`);
    }
  }
}

main().catch(console.error);