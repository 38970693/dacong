# 快速开始指南

本指南将帮助你在 5 分钟内配置好 DaCong Spider 开发环境。

## 前置要求

- Python 3.11 或更高版本
- pip（Python 包管理器）
- Git
- Supabase 账号（免费）

## 步骤 1: 克隆项目

```bash
git clone <repository-url>
cd dacong-spider
```

## 步骤 2: 自动安装

### Linux/Mac

```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

### Windows

```cmd
scripts\setup.bat
```

安装脚本会自动完成：
- ✅ 检查 Python 版本
- ✅ 创建虚拟环境
- ✅ 安装所有依赖
- ✅ 创建 .env 配置文件
- ✅ 创建日志目录

## 步骤 3: 配置 Supabase

### 3.1 获取 Supabase 凭证

1. 访问 https://supabase.com
2. 创建新项目（或使用现有项目）
3. 进入项目设置 → API
4. 复制以下信息：
   - **URL**: `https://your-project.supabase.co`
   - **service_role key**: `eyJhbGc...`（点击显示）

### 3.2 配置环境变量

编辑 `.env` 文件：

```bash
# 必需配置
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

⚠️ **重要**: `service_role` key 拥有完全权限，不要泄露！

## 步骤 4: 创建数据表

在 Supabase SQL Editor 中执行以下 SQL：

```sql
-- 模型原始指标表
CREATE TABLE IF NOT EXISTS model_raw_metrics (
    id BIGSERIAL PRIMARY KEY,
    model_name TEXT NOT NULL,
    platform TEXT NOT NULL,
    downloads BIGINT,
    stars INTEGER,
    likes INTEGER,
    metadata JSONB,
    collected_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(model_name, platform, collected_at::DATE)
);

-- GitHub 仓库指标表
CREATE TABLE IF NOT EXISTS repository_metrics (
    id BIGSERIAL PRIMARY KEY,
    repo_name TEXT NOT NULL,
    stars INTEGER,
    forks INTEGER,
    language TEXT,
    description TEXT,
    url TEXT,
    collected_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(repo_name, collected_at::DATE)
);

-- 热点新闻表
CREATE TABLE IF NOT EXISTS hot_news_raw (
    id BIGSERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    url TEXT,
    source TEXT NOT NULL,
    score INTEGER,
    comments INTEGER,
    collected_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(url, collected_at::DATE)
);

-- 热搜关键词表
CREATE TABLE IF NOT EXISTS trending_keywords (
    id BIGSERIAL PRIMARY KEY,
    keyword TEXT NOT NULL,
    source TEXT NOT NULL,
    count INTEGER DEFAULT 1,
    collected_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(keyword, source, collected_at::DATE)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_model_metrics_platform ON model_raw_metrics(platform);
CREATE INDEX IF NOT EXISTS idx_model_metrics_collected ON model_raw_metrics(collected_at);
CREATE INDEX IF NOT EXISTS idx_repo_metrics_collected ON repository_metrics(collected_at);
CREATE INDEX IF NOT EXISTS idx_news_source ON hot_news_raw(source);
CREATE INDEX IF NOT EXISTS idx_news_collected ON hot_news_raw(collected_at);
```

## 步骤 5: 验证环境

```bash
# 激活虚拟环境（如果还没激活）
source venv/bin/activate  # Linux/Mac
# 或
venv\Scripts\activate     # Windows

# 运行验证脚本
python scripts/verify.py
```

你应该看到所有检查都通过：

```
✅ Python 3.11.x
✅ 所有依赖已安装
✅ .env 文件存在
✅ Supabase 配置正确
```

## 步骤 6: 测试运行

### 6.1 列出所有爬虫

```bash
python main.py --list
```

输出示例：
```
可用的爬虫:
==============================================================
  github               ✅ 启用     间隔: 1 小时
  huggingface          ✅ 启用     间隔: 6 小时
  hackernews           ✅ 启用     间隔: 1 小时
==============================================================
```

### 6.2 测试单个爬虫

```bash
python main.py --spider github
```

如果成功，你会看到：
```
[INFO] 开始运行爬虫: github
[INFO] 获取 GitHub Trending...
[INFO] 写入 25 条数据到 repository_metrics
[INFO] 爬虫 github 运行完成
```

### 6.3 启动调度器

```bash
python main.py
```

调度器会按配置的间隔自动运行所有爬虫。

## 可选配置

### GitHub Token（推荐）

配置 GitHub Token 可以将 API 限额从 60 次/小时提升到 5000 次/小时。

1. 访问 https://github.com/settings/tokens
2. 生成新 token（需要 `public_repo` 权限）
3. 在 `.env` 中添加：

```bash
GITHUB_TOKEN=ghp_your_token_here
```

### Reddit API（可选）

如果需要爬取 Reddit 数据：

1. 访问 https://www.reddit.com/prefs/apps
2. 创建新应用（类型选择 "script"）
3. 在 `.env` 中添加：

```bash
REDDIT_CLIENT_ID=your_client_id
REDDIT_CLIENT_SECRET=your_client_secret
```

### OpenRouter API（可选）

如果需要爬取 OpenRouter 模型数据：

1. 访问 https://openrouter.ai/keys
2. 创建 API Key
3. 在 `.env` 中添加：

```bash
OPENROUTER_API_KEY=sk-or-v1-your_key
```

## 使用 Makefile（推荐）

如果你的系统支持 `make` 命令：

```bash
# 查看所有可用命令
make help

# 初始化开发环境
make init

# 运行测试
make test

# 代码格式化
make format

# 启动爬虫
make run
```

## 常见问题

### Q: Python 版本过低？

A: 安装 Python 3.11 或更高版本：
- **Ubuntu/Debian**: `sudo apt install python3.11`
- **Mac**: `brew install python@3.11`
- **Windows**: 从 https://python.org 下载安装

### Q: pip 安装依赖失败？

A: 尝试升级 pip：
```bash
pip install --upgrade pip
```

### Q: Supabase 连接失败？

A: 检查：
1. `.env` 文件中的 URL 和 Key 是否正确
2. 网络连接是否正常
3. Supabase 项目是否处于活跃状态

### Q: 爬虫运行失败？

A: 查看日志文件：
```bash
tail -f logs/dacong_spider.log
```

## 下一步

- 📖 阅读 [README.md](README.md) 了解更多功能
- 🏗️ 查看 [ARCHITECTURE.md](ARCHITECTURE.md) 了解架构设计
- 🧪 运行测试：`pytest`
- 🐳 使用 Docker 部署：`docker-compose up -d`

## 获取帮助

如果遇到问题：
1. 查看日志文件：`logs/dacong_spider.log`
2. 运行验证脚本：`python scripts/verify.py`
3. 提交 Issue 到 GitHub

---

**恭喜！** 你已经成功配置好 DaCong Spider 开发环境。🎉
