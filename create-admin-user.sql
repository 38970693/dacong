-- 创建管理员账号
-- 使用方式：在 Supabase Dashboard > SQL Editor 中执行

-- 1. 首先在 auth.users 中创建用户（如果不存在）
-- 注意：需要先通过 Supabase Auth 注册这个邮箱，或者使用已存在的用户 ID

-- 2. 将用户添加到 admin_users 表
-- 替换 'YOUR_USER_ID' 为实际的用户 ID
INSERT INTO public.admin_users (id, email, role, is_active, permissions)
VALUES (
  (SELECT id FROM auth.users WHERE email = 'dev@dacong.com' LIMIT 1),
  'dev@dacong.com',
  'admin',
  true,
  '{"all": true}'::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  role = 'admin',
  is_active = true,
  permissions = '{"all": true}'::jsonb,
  updated_at = NOW();

-- 验证是否创建成功
SELECT id, email, role, is_active, created_at 
FROM public.admin_users 
WHERE email = 'dev@dacong.com';
