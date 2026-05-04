# DaCong Spider

AI 模型数据爬虫 — 采集 GitHub Trending、HuggingFace Models、HackerNews、OpenRouter、Reddit 等平台的 AI 相关数据，以及 AI 评测平台排行数据。

## 特性

- 🚀 异步并发爬取，高性能
- 🔄 自动调度，支持自定义间隔
- 📊 数据直接写入 Supabase
- 🐳 Docker 部署支持
- 🔧 灵活的配置管理（基于 Pydantic）
- 🧪 完整的测试覆盖
- 📝 详细的日志记录

## 架构

```
SpiderBase (Strategy + Template Method)
├── GitHubTrendingSpider  → repository_metrics + model_raw_metrics
├── HuggingFaceSpider     → model_raw_metrics
├── HackerNewsSpider      → hot_news_raw
├── OpenRouterSpider      → model_raw_metrics
└── RedditSpider          → hot_news_raw

SpiderFactory (Factory + Registry)
└── @register_spider 装饰器自动注册

AsyncSpiderRunner
└── 并发调度 + 速率限制
```

## 环境要求

- Python 3.11+
- Supabase 账号（用于数据存储）
- 可选：GitHub Token（提高 API 限额）
- 可选：Reddit API 凭证
- 可选：OpenRouter API Key

## 快速开始

### 1. 克隆项目

```bash
git clone <repository-url>
cd dacong-spider
```

### 2. 自动安装（推荐）

**Linux/Mac:**
```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

**Windows:**
```cmd
scripts\setup.bat
```

安装脚本会自动完成：
- 检查 Python 版本
- 创建虚拟环境
- 安装依赖
- 创建 .env 配置文件
- 创建日志目录

### 3. 手动安装

如果自动安装失败，可以手动执行：

```bash
# 创建虚拟环境
python3 -m venv venv

# 激活虚拟环境
# Linux/Mac:
source venv/bin/activate
# Windows:
venv\Scripts\activate

# 安装依赖
pip install -r requirements.txt

# 复制配置文件
cp .env.example .env
```

### 4. 配置环境变量

编辑 `.env` 文件，填入必需的配置：

```bash
# 必需配置
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# 可选配置（提高 API 限额和功能）
GITHUB_TOKEN=ghp_your_github_token
REDDIT_CLIENT_ID=your_reddit_client_id
REDDIT_CLIENT_SECRET=your_reddit_client_secret
OPENROUTER_API_KEY=sk-or-v1-your_key
```

**获取配置的方法：**

- **Supabase**: 项目设置 → API → URL 和 service_role key
- **GitHub Token**: https://github.com/settings/tokens (需要 `public_repo` 权限)
- **Reddit API**: https://www.reddit.com/prefs/apps (创建 script 类型应用)
- **OpenRouter**: https://openrouter.ai/keys

### 5. 验证配置

```bash
python main.py --validate-config
```

### 6. 运行爬虫

```bash
# 启动调度器（持续运行，按配置的间隔自动爬取）
python main.py

# 运行单个爬虫（一次性）
python main.py --spider github

# 运行所有爬虫（一次性）
python main.py --all

# 列出所有可用爬虫
python main.py --list

# 调试模式
python main.py --debug
```

## 命令行参数

| 参数 | 简写 | 说明 |
|------|------|------|
| `--spider <name>` | `-s` | 运行指定的爬虫 |
| `--all` | `-a` | 运行所有启用的爬虫（一次性） |
| `--list` | `-l` | 列出所有可用的爬虫 |
| `--debug` | `-d` | 启用调试模式 |
| `--validate-config` | `-v` | 验证配置文件 |

## AI 评测平台排行

从多个 AI 评测平台抓取排行数据：

```bash
# 抓取所有排行数据
python run_all_rankings.py --save-db

# 单独抓取 LMArena
python run_all_rankings.py --lmarena

# 单独抓取 Artificial Analysis
python run_all_rankings.py --aa

# 启动定时调度（默认每 6 小时）
python scheduler.py

# 每天早上 8 点运行
python scheduler.py --daily
```

### LMArena（HuggingFace 社区投票 ELO）

- 模型排名、ELO 评分、投票数
- 数据来源：https://lmarena.ai

### Artificial Analysis（性能/价格）

- 模型价格、吞吐量、延迟
- 数据来源：https://artificialanalysis.ai

## 配置说明

### 爬虫开关

在 `.env` 中控制爬虫的启用/禁用：

```bash
SPIDER_GITHUB_ENABLED=true
SPIDER_HUGGINGFACE_ENABLED=true
SPIDER_HACKERNEWS_ENABLED=true
SPIDER_OPENROUTER_ENABLED=true
SPIDER_REDDIT_ENABLED=true
```

### 调度间隔

配置每个爬虫的运行间隔（小时）：

```bash
GITHUB_INTERVAL_HOURS=1
HUGGINGFACE_INTERVAL_HOURS=6
HACKERNEWS_INTERVAL_HOURS=1
OPENROUTER_INTERVAL_HOURS=24
REDDIT_INTERVAL_HOURS=24
```

### HTTP 配置

```bash
REQUEST_TIMEOUT=30        # 请求超时（秒）
MAX_RETRIES=3            # 最大重试次数
RETRY_DELAY=5            # 重试间隔（秒）
```

### 代理配置（可选）

```bash
HTTP_PROXY=http://127.0.0.1:7890
HTTPS_PROXY=http://127.0.0.1:7890
```

## Docker 部署

### 方式一：docker-compose（推荐）

```bash
# 1. 配置环境变量
cp .env.example .env
# 编辑 .env 填入配置

# 2. 启动容器
docker-compose up -d

# 3. 查看日志
docker-compose logs -f spider

# 4. 停止容器
docker-compose down
```

### 方式二：Dockerfile

```bash
# 1. 构建镜像
docker build -t dacong-spider .

# 2. 运行容器
docker run -d --name dacong-spider \
  --restart unless-stopped \
  -e SUPABASE_URL=xxx \
  -e SUPABASE_SERVICE_ROLE_KEY=xxx \
  -e GITHUB_TOKEN=xxx \
  dacong-spider

# 3. 查看日志
docker logs -f dacong-spider
```

## GitHub Actions 自动运行

项目已配置 GitHub Actions，可以免费自动运行爬虫。

### 配置步骤

1. 在 GitHub 仓库设置中添加 Secrets：
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `GITHUB_TOKEN`（可选）

2. 工作流会在以下情况触发：
   - 每天 02:00 UTC 自动运行
   - 手动触发：Actions → spider workflow → Run workflow

## 数据表结构

| 表名 | 说明 | 数据来源 |
|------|------|---------|
| `model_raw_metrics` | 模型原始指标 | GitHub, HuggingFace, OpenRouter |
| `repository_metrics` | GitHub 仓库数据 | GitHub Trending |
| `hot_news_raw` | 热点新闻 | HackerNews, Reddit |
| `trending_keywords` | 热搜词 | 各平台聚合 |

## 开发指南

### 添加新爬虫

1. 在 `spiders/` 目录创建新文件
2. 继承 `SpiderBase` 类
3. 使用 `@register_spider` 装饰器注册
4. 实现 `do_fetch` 方法

```python
from core.spider_base import SpiderBase
from core.interfaces import ISpiderRegistry

@ISpiderRegistry.register("my_spider")
class MySpider(SpiderBase):
    @property
    def name(self) -> str:
        return "my_spider"

    async def do_fetch(self, fetcher, writer):
        # 实现爬取逻辑
        data = await fetcher.fetch_json("https://api.example.com/data")
        await writer.write_metrics(data)
```

### 运行测试

```bash
# 运行所有测试
pytest

# 运行测试并查看覆盖率
pytest --cov=. --cov-report=html

# 运行特定测试
pytest tests/test_spiders.py -v
```

### 代码质量检查

```bash
# 格式化代码
black .

# 排序导入
isort .

# 代码检查
ruff check .

# 类型检查
mypy .
```

## 调试

### 单独测试某个爬虫

```python
import asyncio
from spiders.github_trending import GitHubTrendingSpider
from core.implementations import HttpFetcher, SupabaseWriter

async def test():
    fetcher = HttpFetcher()
    writer = SupabaseWriter()
    spider = GitHubTrendingSpider()
    
    await spider.do_fetch(fetcher, writer)
    await fetcher.close()

asyncio.run(test())
```

### 查看日志

```bash
# 实时查看日志
tail -f logs/dacong_spider.log

# 查看最近的错误
grep ERROR logs/dacong_spider.log
```

## 常见问题

### Q: 配置验证失败？

A: 检查 `.env` 文件是否存在，以及必需的配置项是否填写正确：
```bash
python main.py --validate-config
```

### Q: GitHub API 限流？

A: 配置 `GITHUB_TOKEN` 可以将限额从 60 次/小时提升到 5000 次/小时。

### Q: 爬虫运行失败？

A: 查看日志文件 `logs/dacong_spider.log`，检查：
- Supabase 连接是否正常
- API 密钥是否有效
- 网络连接是否正常
- 是否需要配置代理

### Q: 如何修改爬虫间隔？

A: 在 `.env` 文件中修改对应的 `*_INTERVAL_HOURS` 配置，然后重启爬虫。

### Q: 如何禁用某个爬虫？

A: 在 `.env` 文件中设置对应的 `SPIDER_*_ENABLED=false`。

## 项目结构

```
dacong-spider/
├── core/                    # 核心模块
│   ├── base.py             # 基础类
│   ├── factory.py          # 工厂模式
│   ├── fetcher.py          # 数据获取
│   ├── implementations.py  # 接口实现
│   ├── interfaces.py       # 接口定义
│   ├── spider_base.py      # 爬虫基类
│   ├── storage.py          # 数据存储
│   └── writer.py           # 数据写入
├── spiders/                # 爬虫实现
│   ├── github_trending.py
│   ├── huggingface.py
│   ├── hackernews.py
│   ├── openrouter.py
│   └── reddit.py
├── schedulers/             # 调度器
│   ├── scheduler.py
│   └── jobs.py
├── models/                 # 数据模型
├── tests/                  # 测试
├── scripts/                # 脚本
│   ├── setup.sh           # Linux/Mac 安装脚本
│   └── setup.bat          # Windows 安装脚本
├── config.py              # 配置管理
├── main.py                # 主入口
├── requirements.txt       # 依赖
├── .env.example          # 环境变量模板
├── Dockerfile            # Docker 镜像
├── docker-compose.yml    # Docker Compose
└── README.md             # 本文件
```

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

## 联系方式

如有问题，请提交 Issue 或联系维护者。
