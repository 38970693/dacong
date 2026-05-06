# DaCong 项目进度记录

## 最后更新：2026-05-06

---

## ✅ v2.0 已完成

### 前端 (dacong-console)

| 页面 | 路由 | 状态 |
|------|------|------|
| 首页 | `/web` | ✅ |
| 热门 | `/web/trending` | ✅ |
| 关注 | `/web/following` | ✅ |
| 收藏 | `/web/saved` | ✅ |
| 我的 | `/web/profile` | ✅ |
| 榜单 | `/web/ranking` | ✅ |
| AI 榜单 | `/web/ai-rankings` | ✅ |
| 评测列表 | `/web/review` | ✅ |
| 评测详情 | `/web/review/[id]` | ✅ |
| 写评测 | `/web/review/new` | ✅ |
| 搜索 | `/web/search` | ✅ |
| 帖子详情 | `/web/post/[id]` | ✅ |
| 模型详情 | `/web/model/[id]` | ✅ |
| 登录/注册 | `/web/auth/*` | ✅ |
| 审计日志 | `/web/admin/audit-logs` | ✅ |

### 后端 API

| 接口 | 状态 |
|------|------|
| `/api/posts` | ✅ |
| `/api/rankings/[platform]` | ✅ |
| `/api/models` | ✅ |
| `/api/reviews` | ✅ |
| `/api/search` | ✅ |
| `/api/tags` | ✅ |
| `/api/feedback` | ✅ |
| `/api/notifications` | ✅ |
| `/api/audit-logs` | ✅ |

### 技术特性
- [x] Next.js 16.2.4 + TypeScript + Tailwind CSS
- [x] Zustand 状态管理
- [x] 响应式设计（桌面/移动）
- [x] 深色/浅色主题
- [x] 移动端底部导航
- [x] 桌面端侧边栏
- [x] API Routes
- [x] Middleware 路由处理
- [x] GitHub Actions CI/CD
- [x] 单元测试 (vitest)

---

## 🚀 v2.1 规划 - 用户体验升级

### 核心功能

| 功能 | 优先级 | 状态 | 说明 |
|------|--------|------|------|
| 评论系统 | P0 | 📋 | 帖子/评测评论 + 回复 |
| 国际化 (i18n) | P1 | 📋 | 中英文切换 |
| PWA 支持 | P1 | 📋 | 离线缓存 + 安装 |
| 性能优化 | P1 | 📋 | 图片懒加载 + 代码分割 |

### 社区功能

| 功能 | 优先级 | 状态 | 说明 |
|------|--------|------|------|
| 关注体系 | P1 | 📋 | 关注用户/话题 |
| 通知系统 | P1 | 📋 | 评论/点赞/关注通知 |
| 用户积分 | P2 | 📋 | 积分商城 |

### 技术升级

| 功能 | 优先级 | 说明 |
|------|--------|------|
| 无障碍 | P2 | WCAG 2.1 AA |
| SEO 优化 | P2 | Meta 标签 + sitemap |
| 监控告警 | P2 | 错误追踪 + 性能监控 |

---

## 📋 v2.2 规划 - AI 增强

| 功能 | 优先级 | 说明 |
|------|--------|------|
| AI 推荐 | P1 | 个性化内容推荐 |
| 智能摘要 | P2 | AI 生成文章摘要 |
| 模型对比 | P2 | 模型参数对比表 |
| 个性化榜单 | P2 | 用户偏好榜单 |

---

## 💰 v2.3 规划 - 商业化

| 功能 | 优先级 | 说明 |
|------|--------|------|
| 订阅制 | P2 | 高级会员 |
| API 开放 | P2 | 开放平台 |
| 广告系统 | P3 | 广告位管理 |
| 数据分析 | P3 | 流量统计后台 |

---

## 🔴 待解决问题

### Vercel API 重定向问题

**状态**: 待验证

**问题**: API `/api/posts` 返回 HTML 而非 JSON

**建议方案**:
1. 确认是否在生产环境复现
2. 迁移到 Railway + Cloudflare
3. 静态生成 + ISR

---

## 🎯 当前任务

**进行中**: v2.1 规划

### 下一个 Sprint 目标
1. 评论系统 (P0)
2. 国际化 i18n (P1)
3. PWA 支持 (P1)

---

## 📁 项目结构

```
dacong/
├── dacong-console/          # Next.js 前端 (Vercel)
│   ├── src/app/web/         # Web 页面
│   ├── src/app/api/        # API Routes
│   ├── src/components/     # 组件
│   ├── src/stores/         # Zustand
│   └── src/utils/          # 工具函数
├── dacong-worker/           # Node.js Worker (Railway)
│   └── src/
│       ├── crawlers/       # 爬虫
│       ├── moderator.ts    # AI 审核
│       └── trending.ts     # 榜单
├── dacong-spider/           # Python 爬虫 (已归档)
└── .omc/                    # 项目记录
```

**更新于: 2026-05-06**
