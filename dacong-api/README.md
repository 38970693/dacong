# dacong-api

AI 模型排行与社区平台后端，基于 Supabase 构建。

## 技术栈

- **Supabase** — Auth / PostgreSQL / Realtime / Storage
- **Edge Functions** — Deno 运行时，用于内容审核、权重计算、推送触发
- **外部 Worker** — AI 审核、趋势分析（独立 VPS）

## 项目结构

```
dacong-api/
├── supabase/
│   ├── migrations/       # 数据库迁移 SQL
│   └── config.toml        # Supabase 本地配置
├── functions/             # Edge Functions 源码
│   ├── model-rank-calc/   # 榜单权重计算
│   ├── content-moderation/# 内容审核触发
│   └── push-trigger/      # 推送触发器
├── workers/               # 外部 Worker
│   ├── ai-moderation/     # AI 审核 Worker
│   └── trending-calc/      # 趋势分析 Worker
└── README.md
```

## 数据库

核心表：

| 表名 | 说明 |
|------|------|
| profiles | 用户信息 |
| models | AI 模型基础信息 |
| model_raw_metrics | 模型原始指标（爬虫写入） |
| model_ranks | 模型排名（权重计算后） |
| posts | 帖子 |
| comments | 评论 |
| likes | 点赞 |
| favorites | 收藏 |
| follows | 关注 |
| hot_news_raw | 快讯原始数据 |
| search_logs | 搜索日志 |
| trending_keywords | 热搜词 |
| moderation_queue | 审核队列 |
| subscriptions | 用户订阅 |

## 本地开发

```bash
# 安装 Supabase CLI
npm install -g supabase

# 启动本地 Supabase
supabase start

# 应用迁移
supabase db reset

# 部署 Edge Functions
supabase functions deploy
```

## 环境变量

```env
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=
OPENAI_API_KEY=
FCM_SERVER_KEY=
```
