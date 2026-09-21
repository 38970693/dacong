# DaCong - 打工人的科技资讯聚合

面向打工人的科技资讯聚合平台，精选来自 36Kr、虎嗅、新浪财经、网易科技、界面新闻等优质内容源。

## 在线预览

- **线上地址**: https://dacong-weld.vercelapp.com
- **GitHub**: https://github.com/38970693/dacong

## 项目结构

```
dacong/
├── dacong-console/          # Next.js 前端 (部署到 Vercel)
│   ├── src/
│   │   ├── app/             # App Router 页面
│   │   │   ├── api/         # API Routes
│   │   │   ├── page.tsx     # 首页
│   │   │   └── layout.tsx   # 根布局
│   │   ├── components/      # UI 组件
│   │   ├── stores/          # Zustand 状态管理
│   │   ├── types/           # 类型定义
│   │   └── utils/           # 工具函数
│   └── supabase/migrations/ # 数据库迁移脚本
│
└── dacong-worker/           # Node.js Worker (部署到 Railway)
    ├── src/
    │   ├── crawlers/        # 爬虫模块
    │   ├── moderator.ts     # AI 审核
    │   ├── trending.ts      # 榜单计算
    │   └── index.ts         # 入口文件
    └── .github/workflows/   # CI/CD
```

## 技术栈

| 层级 | 技术 |
|------|------|
| 前端 | Next.js 16 + TypeScript + Tailwind CSS + Zustand |
| 后端 Worker | Node.js + TypeScript |
| 数据库 | Supabase (PostgreSQL + Auth + Realtime) |
| 部署 | Vercel (前端) + Railway (Worker) |
| CI/CD | GitHub Actions |

## 数据源

| 源 | 类型 | 状态 |
|----|------|------|
| 36Kr | HTTP API | ✅ |
| 虎嗅 | HTTP API | ✅ |
| 新浪财经 | HTML 解析 | ✅ |
| 网易科技 | JSON API | ✅ |
| 界面新闻 | HTML 解析 | ✅ |
| RSS 订阅 | RSS | ✅ |
| 健康检查 | - | ✅ |

## 功能特性

- **热榜算法**: 基于时间衰减的热度计算（6小时半衰期）
- **AI 审核**: 本地关键词过滤 + 阿里云内容安全（预留）
- **移动优先**: 深色主题，适配手机端浏览
- **实时更新**: 定时调度爬虫（5分钟）+ 榜单计算（1分钟）

## AI 动态

2026-09 起产品聚焦为「AI 动态聚合与洞察平台」——持续呈现 AI 领域的变化，而非一次性快照。
三个带时间维度的视图，统一入口 `/web/dynamics`：

| 视图 | 回答的问题 | 排序依据 |
|------|-----------|---------|
| 资讯流 | 今天 AI 圈发生了什么 | 时间 / 热度 |
| 飙升榜 | 哪个仓库**正在**火 | `velocity`（stars/day 斜率） |
| 模型脉搏 | 哪个模型**在变强** | `eval_date` 历史曲线 |

不做咨询对话、专家市场、支付、RAG / 语义检索，不引入任何 LLM API Key。

- 执行路线图：[docs/AI_DYNAMICS_ROADMAP.md](docs/AI_DYNAMICS_ROADMAP.md)
- 定位决策：[AI_DYNAMICS_REPOSITION_PLAN.md](AI_DYNAMICS_REPOSITION_PLAN.md)
- 数据底座方案：[DATA_FOUNDATION_PLAN.md](DATA_FOUNDATION_PLAN.md)

## 快速启动

### 前端开发

```bash
cd dacong-console
npm install
npm run dev
```

### Worker 开发

```bash
cd dacong-worker
npm install
npm run dev          # 启动 Worker（包含爬虫+审核+榜单）
npm run crawl       # 单独运行爬虫
npm run moderate    # 单独运行审核
npm run trending    # 单独运行榜单计算
```

## 环境变量

### dacong-console/.env.local

```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

### dacong-worker/.env

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

## 数据库迁移

在 Supabase SQL Editor 中运行 `dacong-console/supabase/migrations/001_initial_schema.sql`

## GitHub Secrets 配置

### Vercel 部署

- `VERCEL_TOKEN`: Vercel 个人访问令牌
- `VERCEL_ORG_ID`: Vercel 组织 ID
- `VERCEL_PROJECT_ID`: Vercel 项目 ID

### Worker 部署（Railway）

- `RAILWAY_TOKEN`: Railway 个人令牌
- `RAILWAY_PROJECT_ID`: Railway 项目 ID

## 设计决策

29 个关键设计决策见 [.omc/grill-me/decisions.md](.omc/grill-me/decisions.md)

## 遗留项目（已归档）

以下目录来自旧版本 Flutter 项目，已不再维护：

| 目录 | 说明 |
|------|------|
| `dacong-client/` | Flutter 客户端（已归档） |
| `dacong-admin/` | Flutter 管理后台（已归档） |
| `dacong-api/` | Supabase Edge Functions（已归档） |
| `dacong-docs/` | 旧设计文档（已归档） |
| `dacong-spider/` | Python 爬虫（已归档） |

## 开发进度

见 [.omc/progress.md](.omc/progress.md)
