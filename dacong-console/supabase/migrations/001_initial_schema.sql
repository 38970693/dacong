-- DaCong 项目数据库初始化脚本
-- 运行前请确保已在 Supabase Dashboard 创建项目

-- =============================================
-- 1. 启用必要的扩展
-- =============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- 2. 创建表结构
-- =============================================

-- 爬虫原始数据表
CREATE TABLE IF NOT EXISTS raw_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source TEXT NOT NULL CHECK (source IN ('36kr', 'huxiu')),
  source_url TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  content TEXT,
  author TEXT,
  published_at TIMESTAMP WITH TIME ZONE,
  crawled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected'))
);

-- 审核后的内容表
CREATE TABLE IF NOT EXISTS posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  raw_post_id UUID REFERENCES raw_posts(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  content TEXT,
  source TEXT,
  source_url TEXT,
  views INTEGER DEFAULT 0,
  likes INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 榜单缓存表
CREATE TABLE IF NOT EXISTS trending_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  list_type TEXT NOT NULL CHECK (list_type IN ('hot', 'new')),
  score DOUBLE PRECISION DEFAULT 0,
  rank INTEGER NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(list_type, rank)
);

-- 用户表
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'user' CHECK (role IN ('guest', 'user', 'admin')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 用户行为记录表（用于防刷）
CREATE TABLE IF NOT EXISTS user_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  action_type TEXT NOT NULL CHECK (action_type IN ('view', 'like')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, post_id, action_type)
);

-- =============================================
-- 3. 创建索引
-- =============================================
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_status ON posts(status);
CREATE INDEX IF NOT EXISTS idx_posts_likes ON posts(likes DESC);
CREATE INDEX IF NOT EXISTS idx_trending_cache_list_type ON trending_cache(list_type);
CREATE INDEX IF NOT EXISTS idx_trending_cache_rank ON trending_cache(rank);
CREATE INDEX IF NOT EXISTS idx_user_actions_user_id ON user_actions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_actions_post_id ON user_actions(post_id);

-- =============================================
-- 4. 创建自动更新 updated_at 的触发器
-- =============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER update_posts_updated_at
  BEFORE UPDATE ON posts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- 5. Row Level Security (RLS) 策略
-- =============================================

-- 启用 RLS
ALTER TABLE raw_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE trending_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_actions ENABLE ROW LEVEL SECURITY;

-- raw_posts: 只有 service_role 可以访问
DROP POLICY IF EXISTS "raw_posts_service_only" ON raw_posts;
CREATE POLICY "raw_posts_service_only" ON raw_posts
  FOR ALL TO service_role
  USING (true);

-- posts: 所有人可读，service_role 可写
DROP POLICY IF EXISTS "posts_public_read" ON posts;
CREATE POLICY "posts_public_read" ON posts
  FOR SELECT TO public
  USING (status = 'approved');

DROP POLICY IF EXISTS "posts_service_write" ON posts;
CREATE POLICY "posts_service_write" ON posts
  FOR ALL TO service_role
  USING (true);

-- trending_cache: 所有人可读，service_role 可写
DROP POLICY IF EXISTS "trending_public_read" ON trending_cache;
CREATE POLICY "trending_public_read" ON trending_cache
  FOR SELECT TO public
  USING (true);

DROP POLICY IF EXISTS "trending_service_write" ON trending_cache;
CREATE POLICY "trending_service_write" ON trending_cache
  FOR ALL TO service_role
  USING (true);

-- users: 用户只能读自己的信息
DROP POLICY IF EXISTS "users_own_read" ON users;
CREATE POLICY "users_own_read" ON users
  FOR SELECT TO authenticated
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "users_own_insert" ON users;
CREATE POLICY "users_own_insert" ON users
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = id);

-- user_actions: 用户只能操作自己的数据
DROP POLICY IF EXISTS "user_actions_own" ON user_actions;
CREATE POLICY "user_actions_own" ON user_actions
  FOR ALL TO authenticated
  USING (auth.uid() = user_id);

-- =============================================
-- 6. 创建自动创建用户记录的触发器
-- =============================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, role)
  VALUES (NEW.id, 'user');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- =============================================
-- 7. 插入示例数据（可选，用于测试）
-- =============================================
-- 注释掉以下行以在生产环境中跳过示例数据

/*
INSERT INTO posts (title, content, source, views, likes, comments_count, status)
VALUES
  ('36氪发布最新创业报告', '2024年创业趋势分析...', '36kr', 1234, 89, 12, 'approved'),
  ('虎嗅深度分析文章', '关于科技行业的深度观察...', 'huxiu', 567, 45, 8, 'approved'),
  ('融资快讯 | 某公司完成B轮融资', '金额达数亿元人民币...', '36kr', 890, 67, 23, 'approved')
ON CONFLICT DO NOTHING;
*/