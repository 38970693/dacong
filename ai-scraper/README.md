# AI Model Leaderboard Scraper

多源 AI 模型排行榜爬虫，支持 JavaScript 渲染页面。

## 支持的平台

| 平台 | 描述 | 数据类型 |
|------|------|----------|
| LMArena | lmarena.ai | ELO 分数、投票数、开发者 |
| SWE-bench | swebench.com | 通过率、成本、实例数 |
| Artificial Analysis | artificialanalysis.ai | MMLU、MATH、HumanEval、价格 |
| AI Ping | aiping.dev | 评分、厂商、分类 |

## 安装

```bash
npm install
```

## 使用

### 命令行

```bash
# 爬取所有平台
npm run scrape:all

# 爬取特定平台
npm run scrape:lmarena
npm run scrape:swebench

# 指定输出格式
node src/index.js all --format csv

# 使用代理
node src/index.js all --proxy http://127.0.0.1:7890
```

### 作为库使用

```javascript
import { AIModelScraper } from './src/index.js';

const scraper = new AIModelScraper({
  output: { dir: './data' },
  proxy: { host: '127.0.0.1', port: 7890 }
});

// 爬取所有来源
const data = await scraper.run('all', { format: 'json' });

// 爬取单个来源
const lmarena = await scraper.scrape('lmarena', { category: 'text' });

// 导出数据
await scraper.export(data, { format: 'csv' });
```

## 配置

| 选项 | 默认值 | 描述 |
|------|--------|------|
| headless | true | 浏览器无头模式 |
| timeout | 30000 | 请求超时(ms) |
| retries | 3 | 重试次数 |
| proxy | null | 代理配置 |
| output.dir | ./data | 输出目录 |

## 输出格式

- **JSON**: 完整数据带元数据
- **CSV**: 表格格式，便于 Excel 分析
- **Markdown**: 人可读的表格

## 数据字段

### LMArena
- modelName: 模型名称
- score: ELO 分数
- votes: 投票数
- developer: 开发商
- license: 许可证

### SWE-bench
- modelName: 模型名称
- passRate: 通过率
- averageCost: 平均成本
- instanceCount: 实例数

### Artificial Analysis
- modelName: 模型名称
- mmlu: MMLU 分数
- math: MATH 分数
- humaneval: HumanEval 分数
- price: 每百万 Token 价格

### AI Ping
- modelName: 模型名称
- rating: 综合评分
- vendor: 厂商
- categories: 分类