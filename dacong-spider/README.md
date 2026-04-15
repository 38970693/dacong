# dacong-spider

AI 模型排行与社区平台爬虫层，运行在独立 VPS 上。

## 技术栈

- **Python 3.11+** — 主力语言
- **httpx** — 异步 HTTP 客户端
- **BeautifulSoup4** — HTML 解析
- **Playwright** — JavaScript 渲染页面抓取
- **APScheduler** — 定时任务调度
- **PostgreSQL** — 直写原始数据到 Supabase

## 项目结构

```
dacong-spider/
├── spiders/
│   ├── github_trending.py    # GitHub Trending 爬虫
│   ├── huggingface.py        # HuggingFace 爬虫
│   ├── hackernews.py         # Hacker News 爬虫
│   └── producthunt.py        # Product Hunt 爬虫
├── core/
│   ├── fetcher.py            # 统一请求封装（重试/代理/UA）
│   ├── dedup.py              # 去重逻辑
│   └── writer.py             # Supabase 写入
├── schedulers/
│   └── jobs.py               # APScheduler 定时任务配置
├── requirements.txt
└── README.md
```

## 数据源

| 源 | URL | 写入表 | 爬取频率 |
|----|-----|--------|---------|
| GitHub Trending | https://github.com/trending | model_raw_metrics | 每小时 |
| HuggingFace | https://huggingface.co/models | model_raw_metrics | 每6小时 |
| Hacker News | https://news.ycombinator.com | hot_news_raw | 每15分钟 |
| Product Hunt | https://producthunt.com | hot_news_raw | 每小时 |

## 配置

```python
# config.py
SUPABASE_URL = "https://xxx.supabase.co"
SUPABASE_KEY = "your-service-role-key"

SPIDERS = {
    "github": {"enabled": True, "interval_hours": 1},
    "huggingface": {"enabled": True, "interval_hours": 6},
    "hackernews": {"enabled": True, "interval_minutes": 15},
    "producthunt": {"enabled": True, "interval_hours": 1},
}
```

## 运行

```bash
pip install -r requirements.txt
python -m spiders.github_trending  # 单次运行
python -m schedulers.jobs          # 持续运行（定时调度）
```

## 注意事项

- 严格遵守各平台 robots.txt
- 优先使用官方 API（GitHub API 有 Rate Limit）
- 爬虫只写 raw 表，不做业务计算
- 所有异常写入日志，不阻断其他爬虫
