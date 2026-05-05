# DaCong 项目进度记录

## 最后更新：2026-05-04

---

## ✅ 已完成

### 排行榜数据系统 (dacong-spider)

| 数据源 | 记录数 | 状态 |
|--------|--------|------|
| LMArena | 19,925 | ✅ 正常 |
| Artificial Analysis | 1,205 | ✅ 已修复并同步 |
| SWE-bench | 0 | ❌ API 不可用 |

**新增功能**:
- [x] LMArena 排行榜爬虫（从 HuggingFace API）
- [x] Artificial Analysis 排行榜爬虫（API 端点修复）
- [x] 数据同步到 Supabase `raw_data` 表
- [x] 增量同步逻辑（基于 source_id 去重）
- [x] GitHub Actions 定时任务 (rankings-update.yml)
- [x] 修复 TypeScript 构建错误
- [x] 排行榜前端页面 (/web/ranking, /web/ai-rankings)

**数据文件**:
- `dacong-spider/data/lmarena_rankings.json` (20,029 条)
- `dacong-spider/data/artificial_analysis_rankings.json` (857 条)

---

### 前端 (dacong-console)

#### Web 端页面
| 页面 | 路由 | 状态 | 说明 |
|------|------|------|------|
| 首页 | `/web` | ✅ | 资讯 feed |
| 热门 | `/web/trending` | ✅ | 热门内容 |
| 关注 | `/web/following` | ✅ | 关注内容 |
| 收藏 | `/web/saved` | ✅ | 收藏内容 |
| 我的 | `/web/profile` | ✅ | 个人中心 |
| 榜单 | `/web/ranking` | ✅ | AI 模型排行（新增） |
| 评测 | `/web/review` | ✅ | 模型评测文章（新增） |
| 帖子详情 | `/web/post/[id]` | ✅ | 文章详情页 |

#### 技术特性
- [x] Next.js 16.2.4 + TypeScript + Tailwind CSS
- [x] Zustand 状态管理
- [x] 响应式设计（桌面/移动）
- [x] 深色/浅色主题
- [x] 移动端底部导航
- [x] 桌面端侧边栏
- [x] API Routes
- [x] Middleware 路由处理
- [x] GitHub Actions CI/CD

### 后端 Worker (dacong-worker)
- [x] 爬虫抓取（多数据源）
- [x] AI 内容审核（关键词 + OpenAI）
- [x] 榜单计算（热榜 + 新榜）
- [x] GitHub Actions 定时任务

### 数据库 (Supabase)
- [x] Schema 迁移完成
- [x] 示例数据

---

## 🚀 v2.0 规划 - 核心体验升级

### 页面功能

| 功能 | 优先级 | 状态 | 说明 |
|------|--------|------|------|
| 榜单数据对接 | P0 | 🔄 | 对接 Supabase 获取真实模型数据 |
| 评测文章管理 | P0 | 🔄 | 完整 CRUD + Markdown 编辑器 |
| 搜索功能 | P1 | 📋 | 全文搜索 + 筛选 |
| 标签系统 | P1 | 📋 | 文章标签 + 模型分类标签 |
| 用户系统 | P1 | 📋 | 注册/登录/个人主页 |
| 评论系统 | P2 | 📋 | 帖子评论 + 回复 |
| 点赞收藏 | P2 | 📋 | 互动功能 |

### 技术升级

| 功能 | 优先级 | 说明 |
|------|--------|------|
| 国际化 (i18n) | P1 | 中英文切换 |
| PWA 支持 | P1 | 离线缓存 + 安装 |
| 性能优化 | P1 | 图片懒加载 + 代码分割 |
| 无障碍 | P2 | WCAG 2.1 AA |

---

## 📋 v2.1 规划 - 社区功能

| 功能 | 优先级 | 说明 |
|------|--------|------|
| 关注体系 | P1 | 关注用户/话题 |
| 通知系统 | P1 | 评论/点赞/关注通知 |
| 用户积分 | P2 | 积分商城 |
| 私信功能 | P3 | 用户间私信 |
| 话题广场 | P3 | 话题讨论 |

---

## 🤖 v2.2 规划 - AI 增强

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

**状态**: 已记录，待解决

**问题**: API `/api/posts` 返回 HTML 而非 JSON

**建议方案**:
1. 联系 Vercel 支持
2. 迁移到 Railway + Cloudflare
3. 静态生成 + ISR

---

## 📁 项目结构

```
dacong/
├── dacong-console/          # Next.js 前端
│   └── src/app/web/         # Web 页面
│       ├── page.tsx         # 首页
│       ├── ranking/         # 榜单页
│       ├── review/         # 评测页
│       └── ...
├── dacong-worker/           # Node.js Worker
├── .github/workflows/       # CI/CD
└── .omc/                    # 项目记录
```

---

## 🎯 当前任务

**进行中**: v2.0 功能开发
- [x] 榜单页面框架 (/web/ranking, /web/ai-rankings)
- [x] 评测页面框架
- [x] 榜单数据对接 Supabase
- [x] Artificial Analysis 数据抓取修复
- [x] GitHub Actions 定时任务配置
- [x] 模型 Logo 显示（公司 logo 优先匹配）
- [x] 下拉加载更多功能
- [ ] 评测文章 CRUD（Markdown 编辑器）
- [ ] 搜索功能

**更新于: 2026-05-05**
