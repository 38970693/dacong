/**
 * Arena.ai Model Rankings - By Company
 * 按厂商分类的 AI 模型排行榜
 */

import fs from 'fs';
import path from 'path';

// 最新的 Code Arena 数据 (arena.ai/leaderboard/code)
const codeArenaData = [
  { rank: 1, model: "claude-opus-4-7-thinking", company: "Anthropic", elo: 1571, votes: 2490, price: "$5/$25", context: "1M" },
  { rank: 2, model: "claude-opus-4-7", company: "Anthropic", elo: 1561, votes: 2658, price: "$5/$25", context: "1M" },
  { rank: 3, model: "claude-opus-4-6-thinking", company: "Anthropic", elo: 1548, votes: 5750, price: "$5/$25", context: "1M" },
  { rank: 4, model: "claude-opus-4-6", company: "Anthropic", elo: 1543, votes: 6679, price: "$5/$25", context: "1M" },
  { rank: 5, model: "glm-5.1", company: "Z.ai", elo: 1534, votes: 3412, price: "$1.40/$4.40", context: "202.8K" },
  { rank: 6, model: "claude-sonnet-4-6", company: "Anthropic", elo: 1527, votes: 8709, price: "$3/$15", context: "1M" },
  { rank: 7, model: "kimi-k2.6", company: "Moonshot", elo: 1526, votes: 2130, price: "$0.95/$4", context: "262.1K" },
  { rank: 8, model: "metamuse-spark", company: "Meta", elo: 1509, votes: 1635, price: "N/A", context: "N/A" },
  { rank: 9, model: "gpt-5.5-high (codex-harness)", company: "OpenAI", elo: 1492, votes: 2126, price: "N/A", context: "N/A" },
  { rank: 10, model: "claude-opus-4-5-20251101-thinking-32k", company: "Anthropic", elo: 1491, votes: 13065, price: "$5/$25", context: "200K" },
  { rank: 11, model: "mimo-v2.5-pro", company: "Xiaomi", elo: 1475, votes: 2681, price: "$1/$3", context: "1M" },
  { rank: 12, model: "qwen3.6-plus", company: "Alibaba", elo: 1467, votes: 3716, price: "$0.33/$1.95", context: "1M" },
  { rank: 13, model: "claude-opus-4-5-20251101", company: "Anthropic", elo: 1467, votes: 15309, price: "$5/$25", context: "200K" },
  { rank: 14, model: "gpt-5.4-high (codex-harness)", company: "OpenAI", elo: 1457, votes: 1482, price: "$2.50/$15", context: "1.1M" },
  { rank: 15, model: "deepseek-v4-pro-thinking", company: "DeepSeek", elo: 1455, votes: 1469, price: "$0.43/$0.87", context: "1M" },
  { rank: 16, model: "gemini-3.1-pro-preview", company: "Google", elo: 1453, votes: 7813, price: "$2/$12", context: "1M" },
  { rank: 17, model: "gpt-5.5 (codex-harness)", company: "OpenAI", elo: 1447, votes: 1879, price: "N/A", context: "N/A" },
  { rank: 18, model: "mimo-v2.5", company: "Xiaomi", elo: 1444, votes: 1570, price: "$0.40/$2", context: "1M" },
  { rank: 19, model: "glm-4.7", company: "Z.ai", elo: 1440, votes: 4883, price: "$0.38/$1.74", context: "202.8K" },
  { rank: 20, model: "gemini-3-pro", company: "Google", elo: 1438, votes: 17173, price: "$2/$12", context: "1M" },
  { rank: 21, model: "glm-5", company: "Z.ai", elo: 1437, votes: 6393, price: "$1/$3.20", context: "202.8K" },
  { rank: 22, model: "gpt-5.4-medium (codex-harness)", company: "OpenAI", elo: 1437, votes: 1448, price: "$2.50/$15", context: "1.1M" },
];

// 最新的 Text Arena 数据 (arena.ai/leaderboard/text)
const textArenaData = [
  { rank: 1, model: "claude-opus-4-7-thinking", company: "Anthropic", elo: 1503, votes: 7615, price: "$5/$25", context: "1M" },
  { rank: 2, model: "claude-opus-4-6-thinking", company: "Anthropic", elo: 1502, votes: 22385, price: "$5/$25", context: "1M" },
  { rank: 3, model: "claude-opus-4-6", company: "Anthropic", elo: 1497, votes: 23846, price: "$5/$25", context: "1M" },
  { rank: 4, model: "gemini-3.1-pro-preview", company: "Google", elo: 1493, votes: 28096, price: "$2/$12", context: "1M" },
  { rank: 5, model: "claude-opus-4-7", company: "Anthropic", elo: 1491, votes: 8346, price: "$5/$25", context: "1M" },
  { rank: 6, model: "metamuse-spark", company: "Meta", elo: 1491, votes: 9414, price: "N/A", context: "N/A" },
  { rank: 7, model: "gpt-5.5-high", company: "OpenAI", elo: 1488, votes: 5121, price: "$5/$30", context: "1.1M" },
  { rank: 8, model: "gemini-3-pro", company: "Google", elo: 1486, votes: 41369, price: "$2/$12", context: "1M" },
  { rank: 9, model: "grok-4.20-beta1", company: "xAI", elo: 1480, votes: 17413, price: "N/A", context: "N/A" },
  { rank: 10, model: "grok-4.20-beta-0309-reasoning", company: "xAI", elo: 1477, votes: 16204, price: "$2/$6", context: "2M" },
  { rank: 11, model: "gpt-5.4-high", company: "OpenAI", elo: 1477, votes: 15853, price: "$2.50/$15", context: "1.1M" },
  { rank: 12, model: "gpt-5.2-chat-latest-20260210", company: "OpenAI", elo: 1476, votes: 22311, price: "$1.75/$14", context: "128K" },
  { rank: 13, model: "gpt-5.5", company: "OpenAI", elo: 1475, votes: 5302, price: "$5/$30", context: "1.1M" },
  { rank: 14, model: "grok-4.20-multi-agent-beta-0309", company: "xAI", elo: 1475, votes: 16458, price: "$2/$6", context: "2M" },
  { rank: 15, model: "ernie-5.1-preview", company: "Baidu", elo: 1475, votes: 4738, price: "N/A", context: "N/A" },
  { rank: 16, model: "gemini-3-flash", company: "Google", elo: 1474, votes: 30790, price: "$0.50/$3", context: "1M" },
  { rank: 17, model: "claude-opus-4-5-20251101-thinking-32k", company: "Anthropic", elo: 1473, votes: 37158, price: "$5/$25", context: "200K" },
  { rank: 18, model: "glm-5.1", company: "Z.ai", elo: 1471, votes: 11071, price: "$1.40/$4.40", context: "202.8K" },
  { rank: 19, model: "grok-4.1-thinking", company: "xAI", elo: 1468, votes: 53942, price: "N/A", context: "N/A" },
  { rank: 20, model: "claude-opus-4-5-20251101", company: "Anthropic", elo: 1468, votes: 53597, price: "$5/$25", context: "200K" },
  { rank: 21, model: "gpt-5.4", company: "OpenAI", elo: 1466, votes: 16567, price: "$2.50/$15", context: "1.1M" },
  { rank: 22, model: "mimo-v2.5-pro", company: "Xiaomi", elo: 1463, votes: 5037, price: "$1/$3", context: "1M" },
];

// 按厂商分组
function groupByCompany(data) {
  const grouped = {};
  data.forEach(item => {
    if (!grouped[item.company]) {
      grouped[item.company] = [];
    }
    grouped[item.company].push(item);
  });
  return grouped;
}

// 导出为 Markdown 格式
function exportToMarkdown(codeData, textData) {
  const codeByCompany = groupByCompany(codeData);
  const textByCompany = groupByCompany(textData);

  const companies = [...new Set([...Object.keys(codeByCompany), ...Object.keys(textByCompany)])];

  let md = `# AI Model Rankings by Company\n`;
  md += `> Data source: arena.ai | Updated: ${new Date().toISOString().split('T')[0]}\n\n`;

  md += `## Total: ${companies.length} Companies | ${codeData.length} Code Models | ${textData.length} Text Models\n\n`;

  md += `---\n\n`;

  for (const company of companies.sort()) {
    md += `### ${company}\n\n`;

    // Code Arena
    if (codeByCompany[company]) {
      md += `#### Code Arena\n`;
      md += `| Rank | Model | ELO | Votes | Price | Context |\n`;
      md += `|:---:|------|:---:|-----:|------|------|\n`;
      codeByCompany[company].forEach(item => {
        md += `| ${item.rank} | ${item.model} | ${item.elo} | ${item.votes.toLocaleString()} | ${item.price} | ${item.context} |\n`;
      });
      md += `\n`;
    }

    // Text Arena
    if (textByCompany[company]) {
      md += `#### Text Arena\n`;
      md += `| Rank | Model | ELO | Votes | Price | Context |\n`;
      md += `|:---:|------|:---:|-----:|------|------|\n`;
      textByCompany[company].forEach(item => {
        md += `| ${item.rank} | ${item.model} | ${item.elo} | ${item.votes.toLocaleString()} | ${item.price} | ${item.context} |\n`;
      });
      md += `\n`;
    }

    md += `---\n\n`;
  }

  return md;
}

// 导出为 JSON 格式
function exportToJSON(codeData, textData) {
  return JSON.stringify({
    metadata: {
      source: "arena.ai",
      updated: new Date().toISOString(),
      categories: {
        code: { count: codeData.length },
        text: { count: textData.length }
      }
    },
    rankings: {
      codeArena: codeData,
      textArena: textData
    },
    byCompany: {
      code: groupByCompany(codeData),
      text: groupByCompany(textData)
    }
  }, null, 2);
}

// 导出为 CSV 格式
function exportToCSV(data, filename) {
  let csv = "Rank,Model,Company,ELO,Votes,Price,Context\n";
  data.forEach(item => {
    csv += `${item.rank},"${item.model}",${item.company},${item.elo},${item.votes},"${item.price}",${item.context}\n`;
  });
  return csv;
}

// 主函数
function main() {
  const outputDir = path.join(process.cwd(), 'data', 'rankings');

  // 确保输出目录存在
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  // 导出 Markdown (按厂商分类)
  const markdown = exportToMarkdown(codeArenaData, textArenaData);
  const mdPath = path.join(outputDir, 'rankings-by-company.md');
  fs.writeFileSync(mdPath, markdown, 'utf8');
  console.log(`✓ Exported: ${mdPath}`);

  // 导出 JSON
  const json = exportToJSON(codeArenaData, textArenaData);
  const jsonPath = path.join(outputDir, 'rankings-by-company.json');
  fs.writeFileSync(jsonPath, json, 'utf8');
  console.log(`✓ Exported: ${jsonPath}`);

  // 导出 CSV (Code Arena)
  const csvCode = exportToCSV(codeArenaData, 'code');
  const csvCodePath = path.join(outputDir, 'rankings-code.csv');
  fs.writeFileSync(csvCodePath, csvCode, 'utf8');
  console.log(`✓ Exported: ${csvCodePath}`);

  // 导出 CSV (Text Arena)
  const csvText = exportToCSV(textArenaData, 'text');
  const csvTextPath = path.join(outputDir, 'rankings-text.csv');
  fs.writeFileSync(csvTextPath, csvText, 'utf8');
  console.log(`✓ Exported: ${csvTextPath}`);

  console.log('\n✅ All rankings exported successfully!');
}

main();
