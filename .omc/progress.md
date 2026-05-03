# DaCong 项目进度记录

## 最后更新：2026-05-02 (晚间)

---

## ✅ 已完成

### 前端 (dacong-console)
- [x] Next.js 16.2.4 + TypeScript + Tailwind CSS
- [x] Zustand 状态管理
- [x] API Routes (`/api/posts`, `/api/trending`, `/api/posts/[id]`)
- [x] UI 组件 (PostCard, PostList, TrendingList, TabBar, Messages, Profile)
- [x] 数据库类型定义
- [x] GitHub Actions CI/CD
- [x] 移动端适配（深色主题，移动优先设计）
- [x] Middleware 排除 API 路由

### 后端 Worker (dacong-worker)
- [x] 爬虫（7个数据源）
- [x] AI 审核（本地关键词 + OpenAI 预留）
- [x] 榜单计算（热榜 + 最新榜）
- [x] GitHub Actions 定时任务（每5分钟）

### 数据库 (Supabase)
- [x] Schema 迁移完成
- [x] 示例数据添加（10条 posts + 40条 trending_cache）

---

## 🔴 待解决问题 (2026-05-03)

### Vercel API 重定向问题

**问题**：API `/api/posts` 返回 HTML 而非 JSON，被 Vercel 代理重定向

**症状**：
```
curl https://dacong-weld.vercelapp.com/api/posts
→ 返回 vercelapp.com 指纹脚本 HTML
```

**根本原因**：Vercel 代理层将 API 请求重定向到广告/追踪页面，而不是转发到 Next.js 应用

**已尝试修复**：
1. ✅ 添加 `vercel.json` 禁用 cleanUrls
2. ✅ 添加 `/api/.*` 到 middleware 排除
3. ✅ Vercel 环境变量已配置
4. ❌ 问题仍然存在

**可能原因**：
1. ❌ Vercel 免费版限制 API 路由带宽
2. ❌ 项目被标记为"滥用"或"需要审核"
3. ❌ Vercel 代理层面拦截

**建议方案**：
1. **方案A**：联系 Vercel 支持 - 询问 API 路由问题
2. **方案B**：使用其他平台部署：
   - Railway (简单 Node.js 服务)
   - Cloudflare Pages + Functions
   - AWS Lambda + API Gateway
3. **方案C**：降级 API 复杂度：
   - 静态生成 + ISR
   - CDN 缓存

---

## 📋 完整环境变量

```
# dacong-console/.env.local (本地)
NEXT_PUBLIC_SUPABASE_URL=https://prszkdbdgffbdqclbgol.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Vercel 环境变量 (需配置)
NEXT_PUBLIC_SUPABASE_URL=https://prszkdbdgffbdqclbgol.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 📁 项目结构

```
dacong/
├── dacong-console/          # Next.js 前端 (Vercel)
├── dacong-worker/           # Node.js Worker (GitHub Actions)
├── .github/workflows/       # CI/CD
└── .omc/                    # 项目进度记录
```

---

## 🎯 后续计划

1. (进行中) 解决 Vercel API 重定向问题
2. (待定) 联系 Vercel 支持或迁移到其他平台
3. (可选) 配置 FCM 推送