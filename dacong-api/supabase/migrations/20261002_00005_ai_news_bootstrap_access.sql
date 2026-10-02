-- 初始化新项目时补齐管理端依赖，并限制历史聚合表的写权限。
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  avatar_url TEXT,
  bio TEXT,
  role TEXT NOT NULL DEFAULT 'user',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'user';
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "profiles: own row only" ON public.profiles;
CREATE POLICY "profiles: own row only" ON public.profiles FOR ALL TO authenticated
  USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- 用户可以编辑个人资料，角色只能由服务端授予。
REVOKE INSERT, UPDATE ON public.profiles FROM anon, authenticated;
GRANT INSERT (id, username, avatar_url, bio) ON public.profiles TO authenticated;
GRANT UPDATE (username, avatar_url, bio) ON public.profiles TO authenticated;

-- 原始采集表只允许 service role 写入。
ALTER TABLE public.hot_news_raw ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "hot_news_raw: service role write" ON public.hot_news_raw;
CREATE POLICY "hot_news_raw: service role write" ON public.hot_news_raw
  FOR ALL TO service_role USING (TRUE) WITH CHECK (TRUE);
ALTER POLICY "rising_stars_rankings: service role write" ON public.rising_stars_rankings TO service_role;
ALTER POLICY "model_evaluations: service role write" ON public.model_evaluations TO service_role;
ALTER POLICY "arena_rankings: service role write" ON public.arena_rankings TO service_role;
ALTER POLICY "artificial_analysis_rankings: service role write" ON public.artificial_analysis_rankings TO service_role;
