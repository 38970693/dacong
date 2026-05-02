# DaCong 项目 - Grill-Me 访谈决策记录

> 生成时间: 2026-05-01
> 状态: 已完成所有决策，准备执行

---

## 一、核心业务优先级

| Phase | 功能 | 说明 |
|-------|------|------|
| Phase 1 | 帖子流 + 榜单轮询 + FCM 推送 | MVP 核心 |
| Phase 2 | 私信 Realtime | 后续迭代 |

---

## 二、内容审核策略

### 审核流程
```
爬虫抓取 → raw_posts 表 → status='pending'
        → posts 表立即可见（status='pending'）
        → AI 异步审核 → 违规则 status='rejected' 并隐藏
```

### AI 审核降级策略
1. OpenAI Moderation API 调用（最多 3 次重试，间隔 1s）
2. 重试失败 → 本地关键词黑名单匹配
3. 命中黑名单 → 拒绝
4. 未命中 → 默认通过（标记为 unreviewed）

### 关键词库
- 来源: 开源数据集（如 textfilter）
- 数量: 精简到 500 词以内
- 维护: AI 审核拒绝内容自动学习 + 每月人工审核

---

## 三、数据源与爬虫

### 数据源
- 类型: B 类财经媒体
- 具体: 36氪 + 虎嗅
- 优先级: 同等

### 容错策略
- 单个数据源失败: 静默跳过，记录日志
- 失败率 >50%: 发送告警

### 调度
- 频率: 每 5 分钟
- 工具: Railway 免费版（替代 VPS）

---

## 四、榜单系统

### 计算方式
- 定时预计算（Worker 每分钟一次）
- 时间窗口: 24 小时热榜

### 榜单类型
| 榜单 | 计算公式 |
|------|----------|
| 综合热榜 (hot) | `(views * 0.3 + likes * 0.5 + comments * 0.2) * time_decay` |
| 最新榜 (new) | `ORDER BY created_at DESC` |

### 数据结构
```sql
CREATE TABLE trending_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES posts(id),
  list_type TEXT NOT NULL,  -- 'hot', 'new'
  score FLOAT,
  rank INT,
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(list_type, rank)
);
```

---

## 五、分页与去重

- 分页方案: Cursor 分页（created_at 作为游标）
- 去重策略: 客户端去重 + 下拉刷新清空缓存

---

## 六、推送策略

- 场景: 只推热门快讯（Top 3 进榜）
- 频率控制: 每用户每小时最多 2 条
- 技术: FCM (Firebase Cloud Messaging)

---

## 七、用户认证

### 认证方式
- 游客模式（可浏览，点赞/评论需登录）
- 社交登录: Google + Apple

### 权限模型
| 角色 | 权限 |
|------|------|
| 游客 | 浏览内容 |
| 普通用户 | 浏览 + 点赞 + 评论 |
| 管理员 | 内容审核 |

---

## 八、数据库设计

### 核心表结构

#### raw_posts（爬虫原始数据）
```sql
CREATE TABLE raw_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source TEXT NOT NULL,           -- '36kr', 'huxiu'
  source_url TEXT NOT NULL,
  title TEXT NOT NULL,
  content TEXT,
  author TEXT,
  published_at TIMESTAMP,
  crawled_at TIMESTAMP DEFAULT NOW(),
  status TEXT DEFAULT 'pending'   -- 'pending', 'approved', 'rejected'
);
```

#### posts（审核后的内容）
```sql
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  raw_post_id UUID REFERENCES raw_posts(id),
  title TEXT NOT NULL,
  content TEXT,
  source TEXT,
  source_url TEXT,
  views INT DEFAULT 0,
  likes INT DEFAULT 0,
  comments_count INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

#### trending_cache（榜单缓存）
```sql
CREATE TABLE trending_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES posts(id),
  list_type TEXT NOT NULL,
  score FLOAT,
  rank INT,
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(list_type, rank)
);
```

#### users（用户表）
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  role TEXT DEFAULT 'user',       -- 'guest', 'user', 'admin'
  created_at TIMESTAMP DEFAULT NOW()
);
```

#### user_actions（用户行为记录，防刷）
```sql
CREATE TABLE user_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  post_id UUID REFERENCES posts(id),
  action_type TEXT NOT NULL,  -- 'view', 'like'
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, post_id, action_type)
);
```

### 备注
- comments 表: Phase 2 实现
- user_actions 表: MVP 必须（防刷功能）

---

## 九、RLS 策略

| 表 | SELECT | INSERT | UPDATE | DELETE |
|-----|--------|--------|--------|--------|
| raw_posts | service_role only | service_role | service_role | service_role |
| posts | 所有人 | service_role | service_role | service_role |
| trending_cache | 所有人 | service_role | service_role | service_role |
| user_actions | 用户自己 | authenticated | 用户自己 | 用户自己 |
| users | 用户自己 | service_role | 用户自己 | service_role |

---

## 十、部署架构

### 技术栈变更
- **前端**: Flutter → Next.js + Capacitor
- **原因**: SEO 友好 + 渐进式开发 + JS/TS 生态

### 最终技术栈

| 层级 | 技术 | 说明 |
|------|------|------|
| 前端框架 | Next.js 15 (App Router) | TypeScript |
| 状态管理 | Zustand | 轻量级 |
| UI 组件 | shadcn/ui | Tailwind CSS |
| 后端 | Supabase | PostgreSQL + Auth + Realtime |
| 爬虫 | Python 3.11+ | httpx + BeautifulSoup4 |
| Worker | Railway | 免费 500 小时/月 |
| AI 审核 | 阿里云内容安全 | 1000次/天免费 |
| 部署 | Vercel + Railway | 免费 |
| CI/CD | GitHub Actions | 免费 2000分钟/月 |
| 监控 | Sentry + UptimeRobot | 错误追踪 + 健康检查 |

### 渲染模式

| 页面 | 模式 | 说明 |
|------|------|------|
| 首页/帖子流 | ISR (60s) | 平衡速度和新鲜度 |
| 榜单页 | ISR (30s) | 需要较新数据 |
| 帖子详情页 | SSR | 需要 Open Graph SEO |
| 用户个人页 | CSR | localStorage 存储 |

---

## 十一、API 层设计

| 接口 | 实现方式 | 理由 |
|------|----------|------|
| 帖子列表 | SDK 直接调用 | 简单、无业务逻辑 |
| 榜单数据 | Next.js API Route + 缓存 | 需要聚合计算 |
| 点赞/用户行为 | SDK 直接调用 | Supabase RLS 处理权限 |
| 推送订阅 | Next.js API Route | 需要 FCM 集成 |

---

## 十二、环境变量

```bash
# .env.local (本地开发)
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGci...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGci...
ALIYUN_ACCESS_KEY=xxx
ALIYUN_ACCESS_SECRET=xxx
FCM_SERVER_KEY=xxx
```

- 开发: .env.local
- Vercel: Vercel 环境变量
- Railway: Railway 环境变量
- 密钥: 同一套（开发+生产共用）

---

## 十三、成本估算

### 全免费方案

| 服务 | 方案 | 费用 |
|------|------|------|
| 前端部署 | Vercel Hobby | $0 |
| 数据库 | Supabase Free | $0 |
| 爬虫/Worker | Railway Free | $0 |
| CI/CD | GitHub Actions | $0 |
| AI 审核 | 阿里云内容安全 | $0 (1000次/天) |
| 监控 | Sentry + UptimeRobot | $0 |
| **总计** | | **$0/月** |

---

## 十四、开发计划（AI 辅助）

### 使用 Claude Code + Opus 4.7

| 模块 | AI 辅助后预估 | 说明 |
|------|---------------|------|
| Supabase 配置 | 0.5 小时 | 数据库表、RLS、Auth |
| Next.js 基础 | 2 小时 | scaffold + shadcn/ui |
| 帖子列表页面 | 2 小时 | ISR、下拉刷新、分页 |
| 榜单页面 | 2 小时 | 30s 轮询、UI |
| FCM 推送 | 2 小时 | Firebase 配置 |
| 爬虫开发 | 4 小时 | 36kr + 虎嗅解析 |
| AI 审核 | 2 小时 | 阿里云集成 |
| 榜单计算 | 1 小时 | 预计算逻辑 |
| 测试 + 部署 | 2 小时 | GitHub Actions |
| **总计** | **~1.5 天** | **提升 6 倍效率** |

---

## 十五、技术债务策略

### Phase 1 允许的债务
| 类型 | 容忍度 |
|------|--------|
| 临时方案 | ⚠️ 中等 |
| 缺失测试 | ✅ 允许（AI 快速补） |
| 缺失文档 | ✅ 允许（AI 快速生成） |
| 重复代码 | ✅ 允许（AI 重构） |
| 硬编码 | ⚠️ 低（关键配置不硬编码） |

### 核心原则
- ❌ RLS 不能妥协
- ❌ 审核流程不能跳过
- ❌ 安全策略不能削弱
- ✅ 其他可灵活

---

## 十六、基础设施变更

- ~~GitLab~~ → **GitHub**（GitLab 国内不支持）
- ~~VPS~~ → **Railway**（免费 500小时/月）

---

## 下一步行动

1. 创建 GitHub 仓库
2. 配置 Supabase 项目
3. 搭建 Next.js 项目
4. 实现核心功能
5. 部署 + 监控