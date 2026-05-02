# Grill-Me 访谈决策记录

## 已确认的架构决策

### 1. 核心业务优先级
- **Phase 1**: 帖子流（下拉刷新）+ 榜单轮询 + FCM 推送
- **Phase 2**: 私信 Realtime

### 2. 内容审核策略
- **方案**: 非阻塞式审核（先发后审）
- **降级策略**: 分级降级（重试 3 次 → 本地关键词黑名单 → 默认通过）
- **关键词库**: 开源数据集 + 人工精简到 500 词

### 3. 数据源与爬虫
- **MVP 数据源**: B 类财经媒体（36氪 + 虎嗅）
- **容错策略**: 静默跳过 + 失败率 >50% 告警
- **调度频率**: 统一 5 分钟

### 4. 榜单系统
- **计算方式**: 定时预计算（Worker 每分钟一次）
- **时间窗口**: 24 小时热榜
- **榜单类型**: 综合热榜 + 最新榜
- **数据结构**: 单表 + 类型字段（list_type）

### 5. 分页与去重
- **分页方案**: Cursor 分页（created_at 作为游标）
- **去重策略**: 客户端去重 + 下拉刷新清空缓存

### 6. 推送策略
- **MVP 场景**: 只推热门快讯（Top 3 进榜）
- **频率控制**: 每用户每小时最多 2 条

### 7. 用户认证
- **认证方式**: 游客模式 + Google/Apple 登录
- **权限模型**: 三级（游客/普通用户/管理员）

### 8. 数据库设计
- **核心表**: raw_posts, posts, trending_cache, users, user_actions
- **comments 表**: Phase 2
- **user_actions 表**: MVP 就要（防刷）

### 9. RLS 策略
- **raw_posts**: 只有 Service Role 可访问
- **posts**: 所有人可读，只有 Service Role 可写
- **user_actions**: 用户只能操作自己的数据

### 10. 爬虫部署
- **架构**: 单进程 APScheduler + 健康检查端点
- **位置**: VPS (Ubuntu 22.04)

### 11. Worker 实现
- **方案**: 全部在 VPS Python Worker 中
- **任务**: crawler.py (5分钟) + moderator.py (30秒) + trending.py (1分钟)

### 12. 前端技术栈（重大变更）
- **从 Flutter 切换到 Next.js + Capacitor**
- **理由**: SEO 友好 + 渐进式开发 + JS/TS 生态
- **Phase 1**: 只做 Web（Next.js + Vercel）
- **Phase 2**: Capacitor 打包成 App

---

## 新技术栈总览

### 前端
- **框架**: Next.js 15 (App Router) + TypeScript
- **状态管理**: Zustand
- **UI 组件**: shadcn/ui (Tailwind CSS)
- **移动端**: Capacitor (Phase 2)
- **部署**: Vercel

### 后端
- **BaaS**: Supabase (PostgreSQL + Auth + Realtime + Storage)
- **Edge Functions**: Deno (如需要)

### 爬虫 + Worker
- **语言**: Python 3.11+
- **调度**: APScheduler
- **AI 审核**: OpenAI Moderation API
- **部署**: VPS (2核4G)

### 基础设施
- **CI/CD**: GitLab CI/CD
- **监控**: 健康检查端点 + UptimeRobot
- **推送**: FCM (Firebase Cloud Messaging)
