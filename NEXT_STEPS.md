# 后台管理系统 - 下一步操作

## 当前状态
✅ Edge Functions 已部署  
✅ Flutter 后台应用已启动  
✅ 数据库迁移文件已创建  
⚠️ 需要在 Supabase Dashboard 执行 SQL

---

## 立即执行：在 Supabase Dashboard 创建数据库表

### 步骤 1：执行 SQL 脚本

1. 打开 Supabase Dashboard: https://supabase.com/dashboard
2. 选择项目 `twrxnqrisplmetbceyqm`
3. 进入 **SQL Editor**
4. 复制并执行以下文件内容：
   - `dacong-api/supabase/migrations/20260420000001_setup_admin_system.sql`

### 步骤 2：创建管理员账号

**选项 A - 如果 dev@dacong.com 已存在于 auth.users：**

在 SQL Editor 执行：
```sql
INSERT INTO public.admin_users (id, email, role, is_active, permissions)
SELECT id, email, 'admin', true, '{"all": true}'::jsonb
FROM auth.users 
WHERE email = 'dev@dacong.com'
ON CONFLICT (id) DO UPDATE SET
  role = 'admin',
  is_active = true,
  permissions = '{"all": true}'::jsonb,
  updated_at = NOW();
```

**选项 B - 如果用户不存在：**

1. 进入 **Authentication > Users**
2. 点击 **Add user**
3. 填写：
   - Email: `dev@dacong.com`
   - Password: 自定义密码（记住它！）
   - Auto Confirm User: ✅ 勾选
4. 创建后，执行选项 A 的 SQL

### 步骤 3：验证设置

在 SQL Editor 执行：
```sql
SELECT 
  au.id, 
  au.email, 
  au.role, 
  au.is_active, 
  au.created_at,
  u.email as auth_email
FROM public.admin_users au
LEFT JOIN auth.users u ON u.id = au.id
WHERE au.email = 'dev@dacong.com';
```

应该返回 1 行数据，显示管理员信息。

---

## 测试登录

1. 打开后台：http://localhost:8080
2. 使用以下凭据登录：
   - Email: `dev@dacong.com`
   - Password: 创建用户时设置的密码

---

## 如果遇到问题

### 登录失败 401
- 检查 `auth.users` 表中是否存在该用户
- 检查 `admin_users` 表中是否有对应记录
- 验证密码是否正确

### 表不存在错误
- 确认已在 SQL Editor 执行迁移脚本
- 检查 Supabase Dashboard > Table Editor 是否显示 3 个新表

### Flutter 应用空白
- 检查浏览器控制台是否有错误
- 确认 `start-dev-with-config.bat` 中的 `SUPABASE_ANON_KEY` 已填写

---

## 相关文件

- 迁移脚本: `dacong-api/supabase/migrations/20260420000001_setup_admin_system.sql`
- 完整 SQL: `setup-admin-complete.sql`
- 启动脚本: `dacong-admin/start-dev-with-config.bat`
- 进度文档: `ADMIN_SETUP_PROGRESS.md`
