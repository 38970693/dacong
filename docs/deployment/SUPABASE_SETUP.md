# Supabase 配置指南

## 概述

本文档详细说明如何配置 Supabase 项目，包括数据库、认证、存储、Edge Functions 等。

---

## 1. 创建 Supabase 项目

### 1.1 注册账号

1. 访问 https://supabase.com
2. 使用 GitHub/Google 账号登录
3. 验证邮箱

### 1.2 创建新项目

1. 点击 "New Project"
2. 填写项目信息：
   - **Name**: `dacong-prod`
   - **Database Password**: 生成强密码（保存到密码管理器）
   - **Region**: 选择最近的区域（如 `ap-southeast-1` 新加坡）
   - **Pricing Plan**: 选择 Free 或 Pro

3. 等待项目初始化（约 2 分钟）

### 1.3 获取项目凭证

访问 Settings > API，获取以下信息：

```env
# Project URL
SUPABASE_URL=https://xxxxx.supabase.co

# API Keys
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Database Connection
DATABASE_URL=postgresql://postgres:[PASSWORD]@db.xxxxx.supabase.co:5432/postgres
```

**安全提示**：
- `SUPABASE_ANON_KEY`：可以在前端使用（受 RLS 保护）
- `SUPABASE_SERVICE_ROLE_KEY`：仅在服务端使用，绝不暴露到前端

---

## 2. 数据库配置

### 2.1 安装 Supabase CLI

```bash
# macOS/Linux
brew install supabase/tap/supabase

# Windows
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase

# npm（跨平台）
npm install -g supabase

# 验证安装
supabase --version
```

### 2.2 登录并链接项目

```bash
# 登录
supabase login

# 链接到远程项目
cd dacong-api
supabase link --project-ref xxxxx

# 验证链接
supabase projects list
```

获取 `project-ref`：
- Supabase Dashboard > Settings > General > Reference ID

### 2.3 运行数据库迁移

```bash
# 查看本地迁移文件
ls -la supabase/migrations/

# 查看远程数据库状态
supabase db remote list

# 执行迁移
supabase db push

# 验证迁移结果
supabase db remote list
```

**迁移文件执行顺序**：
1. `001_initial_schema.sql` - 基础表结构
2. `20260417000001_create_raw_data.sql` - 原始数据表
3. `20260417000002_create_generated_content.sql` - 生成内容表
4. `20260417000003_create_published_content.sql` - 发布内容表
5. `20260417000004_create_user_feedback.sql` - 用户反馈表
6. `20260417000005_create_scenario_recommendations.sql` - 场景推荐表
7. `20260417000006_create_spider_logs.sql` - 爬虫日志表
8. `20260417000010_create_triggers.sql` - 触发器
9. `20260417000020_create_rls_policies.sql` - RLS 策略
10. `20260417000030_create_views.sql` - 视图
11. `20260417000040_seed_data.sql` - 种子数据
12. `20260417100000_create_admin_tables.sql` - 管理后台表
13. `20260417110000_create_comments.sql` - 评论系统
14. `20260417_week3_analytics_admin.sql` - 分析和管理功能

### 2.4 验证数据库结构

```bash
# 连接到数据库
psql $DATABASE_URL

# 列出所有表
\dt

# 查看表结构
\d raw_data
\d generated_content
\d published_content

# 检查索引
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

# 检查外键约束
SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public';
```

---

## 3. Row Level Security (RLS) 配置

### 3.1 RLS 策略概述

RLS 确保用户只能访问自己有权限的数据。

**策略类型**：
- `SELECT` - 读取权限
- `INSERT` - 创建权限
- `UPDATE` - 更新权限
- `DELETE` - 删除权限

### 3.2 验证 RLS 策略

```sql
-- 查看所有 RLS 策略
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- 检查表是否启用 RLS
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
```

### 3.3 常见 RLS 策略示例

```sql
-- 用户只能查看已发布的内容
CREATE POLICY "Users can view published content"
ON published_content
FOR SELECT
USING (status = 'published');

-- 用户只能编辑自己的反馈
CREATE POLICY "Users can update own feedback"
ON user_feedback
FOR UPDATE
USING (auth.uid() = user_id);

-- 管理员可以查看所有数据
CREATE POLICY "Admins can view all"
ON published_content
FOR SELECT
USING (
    auth.jwt() ->> 'role' = 'admin'
);
```

### 3.4 测试 RLS 策略

```sql
-- 以匿名用户身份测试
SET ROLE anon;
SELECT * FROM published_content;  -- 应该只返回已发布内容

-- 以认证用户身份测试
SET ROLE authenticated;
SELECT * FROM user_feedback WHERE user_id = 'test-user-id';

-- 恢复默认角色
RESET ROLE;
```

---

## 4. Storage 配置

### 4.1 创建 Storage Bucket

1. 访问 Supabase Dashboard > Storage
2. 点击 "New Bucket"
3. 创建以下 Buckets：

| Bucket 名称 | 公开访问 | 文件大小限制 | 允许的文件类型 |
|------------|---------|------------|--------------|
| `avatars` | 是 | 2MB | image/jpeg, image/png, image/webp |
| `content-images` | 是 | 5MB | image/* |
| `attachments` | 否 | 10MB | * |

### 4.2 配置 Storage 策略

```sql
-- 允许用户上传头像
CREATE POLICY "Users can upload own avatar"
ON storage.objects
FOR INSERT
WITH CHECK (
    bucket_id = 'avatars' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- 允许用户查看所有头像
CREATE POLICY "Anyone can view avatars"
ON storage.objects
FOR SELECT
USING (bucket_id = 'avatars');

-- 允许用户删除自己的头像
CREATE POLICY "Users can delete own avatar"
ON storage.objects
FOR DELETE
USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
);
```

### 4.3 测试 Storage

```bash
# 使用 Supabase JS 客户端测试
curl -X POST \
  https://xxxxx.supabase.co/storage/v1/object/avatars/test.jpg \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: image/jpeg" \
  --data-binary @test.jpg
```

---

## 5. Authentication 配置

### 5.1 启用认证提供商

访问 Supabase Dashboard > Authentication > Providers

**推荐启用**：
- Email/Password（默认启用）
- Google OAuth
- GitHub OAuth
- Apple（iOS 应用必需）

### 5.2 配置 Email 模板

访问 Authentication > Email Templates

**自定义模板**：
- Confirm Signup（确认注册）
- Magic Link（魔法链接登录）
- Change Email Address（更改邮箱）
- Reset Password（重置密码）

**示例模板**：
```html
<h2>欢迎来到 DaCong！</h2>
<p>点击下面的链接确认您的邮箱：</p>
<p><a href="{{ .ConfirmationURL }}">确认邮箱</a></p>
<p>如果您没有注册 DaCong 账号，请忽略此邮件。</p>
```

### 5.3 配置重定向 URL

访问 Authentication > URL Configuration

**添加允许的重定向 URL**：
```
https://app.dacong.com/**
https://dacong.com/**
http://localhost:3000/**  # 开发环境
```

### 5.4 配置 JWT 设置

访问 Settings > API > JWT Settings

**推荐配置**：
- JWT Expiry: `3600` (1 小时)
- Refresh Token Expiry: `2592000` (30 天)

### 5.5 测试认证

```bash
# 注册新用户
curl -X POST \
  https://xxxxx.supabase.co/auth/v1/signup \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePassword123!"
  }'

# 登录
curl -X POST \
  https://xxxxx.supabase.co/auth/v1/token?grant_type=password \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePassword123!"
  }'
```

---

## 6. Edge Functions 配置

### 6.1 Edge Functions 概述

DaCong 使用以下 Edge Functions：

| 函数名 | 用途 | 触发方式 |
|--------|------|---------|
| `rank-calc` | 计算内容热度排名 | 定时任务 |
| `moderation-trigger` | 内容审核 | 数据库触发器 |
| `push-trigger` | 推送通知 | 数据库触发器 |

### 6.2 部署 Edge Functions

```bash
cd dacong-api/supabase/functions

# 部署单个函数
supabase functions deploy rank-calc

# 部署所有函数
supabase functions deploy rank-calc
supabase functions deploy moderation-trigger
supabase functions deploy push-trigger

# 查看已部署的函数
supabase functions list
```

### 6.3 配置函数环境变量

```bash
# 设置环境变量
supabase secrets set OPENROUTER_API_KEY=sk-or-xxxxx
supabase secrets set GITHUB_TOKEN=ghp_xxxxx

# 查看已设置的密钥（不显示值）
supabase secrets list

# 删除密钥
supabase secrets unset OPENROUTER_API_KEY
```

### 6.4 测试 Edge Functions

```bash
# 本地测试
supabase functions serve rank-calc

# 调用本地函数
curl -X POST \
  http://localhost:54321/functions/v1/rank-calc \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"content_id": "test-id"}'

# 调用生产函数
curl -X POST \
  https://xxxxx.supabase.co/functions/v1/rank-calc \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"content_id": "test-id"}'
```

### 6.5 查看函数日志

```bash
# 查看最近的日志
supabase functions logs rank-calc

# 实时查看日志
supabase functions logs rank-calc --follow

# 查看特定时间范围的日志
supabase functions logs rank-calc --since "2024-01-01" --until "2024-01-02"
```

---

## 7. 数据库优化

### 7.1 创建性能索引

```sql
-- 内容查询索引
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_published_content_status_created 
ON published_content(status, created_at DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_published_content_category 
ON published_content(category);

-- 用户反馈索引
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_feedback_content 
ON user_feedback(content_id);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_feedback_user 
ON user_feedback(user_id);

-- 评论索引
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_comments_content 
ON comments(content_id, created_at DESC);

-- 全文搜索索引
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_published_content_search 
ON published_content USING gin(to_tsvector('chinese', title || ' ' || content));
```

### 7.2 启用查询统计

```sql
-- 启用 pg_stat_statements 扩展
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- 查看慢查询
SELECT 
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    max_exec_time
FROM pg_stat_statements
WHERE mean_exec_time > 100  -- 平均执行时间 > 100ms
ORDER BY mean_exec_time DESC
LIMIT 20;
```

### 7.3 配置连接池

访问 Supabase Dashboard > Settings > Database

**推荐配置**：
- Pool Mode: `Transaction`
- Pool Size: `15` (Free Plan)
- Max Client Connections: `100`

### 7.4 定期维护

```sql
-- 分析表统计信息
ANALYZE raw_data;
ANALYZE generated_content;
ANALYZE published_content;

-- 清理死元组
VACUUM ANALYZE published_content;

-- 重建索引（如果需要）
REINDEX TABLE published_content;
```

---

## 8. 监控和告警

### 8.1 启用 Supabase 监控

访问 Supabase Dashboard > Reports

**监控指标**：
- API 请求数
- 数据库连接数
- 存储使用量
- 带宽使用量
- Edge Functions 调用次数

### 8.2 配置告警

访问 Settings > Billing > Usage Alerts

**推荐告警**：
- Database Size > 80%
- API Requests > 80% of quota
- Storage > 80% of quota

### 8.3 查看实时日志

```bash
# 查看 API 日志
supabase logs api

# 查看数据库日志
supabase logs db

# 查看实时日志
supabase logs api --follow
```

---

## 9. 备份和恢复

### 9.1 自动备份

Supabase 自动备份：
- Free Plan: 每日备份，保留 7 天
- Pro Plan: 每日备份，保留 30 天

### 9.2 手动备份

```bash
# 导出整个数据库
pg_dump $DATABASE_URL > backup_$(date +%Y%m%d).sql

# 导出特定表
pg_dump $DATABASE_URL -t published_content > published_content_backup.sql

# 导出数据（不含结构）
pg_dump $DATABASE_URL --data-only > data_backup.sql
```

### 9.3 恢复数据

```bash
# 恢复整个数据库
psql $DATABASE_URL < backup_20240417.sql

# 恢复特定表
psql $DATABASE_URL < published_content_backup.sql
```

---

## 10. 安全检查清单

- [ ] 已启用 RLS 策略
- [ ] `SUPABASE_SERVICE_ROLE_KEY` 未暴露到前端
- [ ] 已配置 Storage 访问策略
- [ ] 已限制允许的重定向 URL
- [ ] 已启用 Email 验证
- [ ] 已配置强密码策略
- [ ] 已启用 2FA（管理员账号）
- [ ] 已配置 IP 白名单（如需要）
- [ ] 已启用 SSL/TLS
- [ ] 已配置 CORS 策略

---

## 11. 性能优化清单

- [ ] 已创建必要的索引
- [ ] 已启用查询统计
- [ ] 已配置连接池
- [ ] 已启用 CDN（Cloudflare）
- [ ] 已优化慢查询
- [ ] 已配置缓存策略
- [ ] 已启用 gzip 压缩
- [ ] 已优化图片大小

---

## 常见问题

### 数据库迁移失败

**问题**：`supabase db push` 失败

**解决方案**：
```bash
# 查看详细错误
supabase db push --debug

# 重置远程数据库（危险！）
supabase db reset --linked

# 手动执行迁移
psql $DATABASE_URL < supabase/migrations/xxx.sql
```

### RLS 策略不生效

**问题**：用户可以访问不应该访问的数据

**解决方案**：
```sql
-- 检查表是否启用 RLS
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'published_content';

-- 启用 RLS
ALTER TABLE published_content ENABLE ROW LEVEL SECURITY;

-- 测试策略
SET ROLE anon;
SELECT * FROM published_content;
RESET ROLE;
```

### Edge Functions 超时

**问题**：函数执行超过 10 秒

**解决方案**：
1. 优化函数代码
2. 使用异步处理
3. 拆分为多个小函数
4. 考虑使用 VPS 处理长时间任务

---

## 下一步

1. 配置域名和 SSL：[DOMAIN_SSL_SETUP.md](./DOMAIN_SSL_SETUP.md)
2. 部署前端应用：[PRODUCTION_DEPLOYMENT.md](./PRODUCTION_DEPLOYMENT.md)
3. 配置监控：[MONITORING_SETUP.md](./MONITORING_SETUP.md)
