# DaCong 项目进度记录

## 最后更新：2026-05-02

---

## ✅ 已完成

### 前端 (dacong-console)
- [x] Next.js 16.2.4 + TypeScript + Tailwind CSS
- [x] Zustand 状态管理
- [x] API Routes (`/api/posts`, `/api/trending`, `/api/posts/[id]`)
- [x] UI 组件 (PostCard, PostList, TrendingList, TabBar, Messages, Profile)
- [x] 数据库类型定义
- [x] Supabase 环境变量配置
- [x] GitHub Actions CI/CD
- [x] 移动端适配（深色主题，移动优先设计）

### 后端 Worker (dacong-worker)
- [x] 爬虫（7个数据源）：
  - 36kr (HTTP API)
  - 虎嗅 (HTTP API)
  - 新浪财经 (HTML 解析)
  - 网易科技 (JSON API)
  - 界面新闻 (HTML 解析)
  - RSS 订阅源 (36kr, 虎嗅, 界面)
- [x] AI 审核（本地关键词 + 阿里云预留）
- [x] 榜单计算（热榜 + 时间衰减）
- [x] 健康检查端点 (`/health`, `/health/live`, `/health/ready`)
- [x] 定时调度（爬虫5分钟/审核30秒/榜单1分钟）
- [x] GitHub Actions CI/CD

### 数据库 (Supabase)
- [x] Schema 设计 (`dacong-console/supabase/migrations/001_initial_schema.sql`)
- [x] RLS 策略配置
- [x] 触发器和索引

### 项目架构
- [x] Grill-Me 访谈（29个关键决策）
- [x] 完整技术栈设计文档
- [x] 并行开发计划（3大工程）

---

## 📋 环境变量

```
# dacong-console/.env.local
NEXT_PUBLIC_SUPABASE_URL=https://prszkdbdgffbdqclbgol.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# dacong-worker/.env
SUPABASE_URL=https://prszkdbdgffbdqclbgol.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 🔜 待手动完成

### 1. Supabase 数据库迁移（最关键）
在 [Supabase SQL Editor](https://supabase.com/dashboard) 执行：
```sql
-- 运行 dacong-console/supabase/migrations/001_initial_schema.sql 中的内容
```

### 2. 添加示例数据
迁移后可在 SQL Editor 执行：
```sql
INSERT INTO posts (title, content, source, views, likes, comments_count, status)
VALUES
  ('36氪发布最新创业报告', '2024年创业趋势分析...', '36kr', 1234, 89, 12, 'approved'),
  ('虎嗅深度分析文章', '关于科技行业的深度观察...', 'huxiu', 567, 45, 8, 'approved');
```

### 3. GitHub 配置
- [x] 创建 GitHub 仓库或更新远程地址
- [x] 推送代码到 GitHub
- [x] 添加 Secrets：
  - `VERCEL_TOKEN`
  - `VERCEL_ORG_ID` = team_V7Og2pSepqErwAMoE1G3psTu
  - `VERCEL_PROJECT_ID` = prj_iCcurdVp4XJEQmRUwhuSTFGvp55
  - [ ] `SUPABASE_URL`
  - [ ] `SUPABASE_SERVICE_ROLE_KEY`

### 4. 部署
- [x] 部署前端到 Vercel (https://dacong-weld.vercelapp.com)
- [ ] 部署 Worker 到 Railway
- [ ] Supabase 数据库迁移（等恢复后执行）

### 5. 可选功能（Phase 2+）
- [ ] FCM 推送集成
- [ ] Google/Apple 登录
- [ ] 阿里云内容安全 API
- [ ] 评论功能

---

## 📁 项目结构（当前）

```
dacong/
├── dacong-console/          # Next.js 前端
│   ├── src/
│   │   ├── app/
│   │   │   ├── api/        # API Routes (posts, trending)
│   │   │   ├── layout.tsx  # 根布局
│   │   │   └── page.tsx     # 首页
│   │   ├── components/      # UI 组件
│   │   ├── stores/          # Zustand 状态管理
│   │   ├── types/           # 类型定义
│   │   └── utils/supabase/  # Supabase 客户端
│   ├── supabase/migrations/ # 数据库迁移脚本
│   └── .github/workflows/   # CI/CD
│
└── dacong-worker/           # Node.js Worker
    ├── src/
    │   ├── crawlers/        # 爬虫模块 (36kr, huxiu, sina, 163tech, jiemian, rss, health)
    │   ├── moderator.ts     # AI 审核
    │   ├── trending.ts      # 榜单计算
    │   ├── supabase.ts      # Supabase 客户端
    │   ├── logger.ts        # 日志
    │   ├── config.ts        # 配置
    │   └── types.ts         # 类型
    └── .github/workflows/   # CI/CD
```

---

## 🎯 下一步行动

### 立即执行（5分钟）
1. 打开 [Supabase Dashboard](https://supabase.com/dashboard)
2. 选择项目 → SQL Editor
3. 粘贴并运行 `dacong-console/supabase/migrations/001_initial_schema.sql`

### 验证迁移成功
```sql
SELECT * FROM posts LIMIT 1;
-- 应返回表结构而非错误
```

---

## 💡 快速启动命令

```bash
# 前端开发
cd dacong-console && npm run dev

# Worker 开发
cd dacong-worker && npm run dev

# 单独运行爬虫
cd dacong-worker && npm run crawl

# 单独运行审核
cd dacong-worker && npm run moderate

# 单独运行榜单计算
cd dacong-worker && npm run trending
```