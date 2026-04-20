# 后台数据加载失败解决方案

## 问题

后台页面显示多个加载失败错误：
- 实时概览：Failed to fetch get-realtime-stats
- 趋势分析：Failed to fetch get-trend-data
- 待处理事项：Table 'public.reports' not found

## 原因

1. Edge Functions 还没有部署到 Supabase
2. 数据库表可能还没有创建

## 解决方案

### 方案 1：部署 Edge Functions（推荐）

运行部署脚本：

```bash
# Windows
deploy-admin-functions.bat

# Linux/Mac
./deploy-admin-functions.sh
```

### 方案 2：手动部署

```bash
cd dacong-api/supabase/functions

# 部署所需函数
supabase functions deploy get-realtime-stats
supabase functions deploy get-trend-data
supabase functions deploy admin-stats
supabase functions deploy admin-content-management
supabase functions deploy admin-users-list
supabase functions deploy admin-comment-moderation
supabase functions deploy admin-audit-logs
```

### 方案 3：创建缺失的数据库表

如果部署后仍然报错 "table not found"，需要运行数据库迁移：

```bash
cd dacong-api
supabase db push
```

## 验证部署

部署完成后，刷新后台页面，数据应该能正常加载。

## 临时解决方案

如果暂时不想部署，可以继续使用"开发模式进入"按钮访问后台，只是数据看板会显示加载失败。其他功能（用户管理、内容管理等）可能仍然可用。
