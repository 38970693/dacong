-- 创建管理后台相关表
-- 运行方式：supabase db push

BEGIN;

-- ── 1. admin_users 管理员表 ────────────────────────────────

CREATE TABLE IF NOT EXISTS public.admin_users (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email       TEXT NOT NULL UNIQUE,
  role        TEXT NOT NULL DEFAULT 'moderator', -- admin / moderator / viewer
  permissions JSONB DEFAULT '{}',
  is_active   BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;

-- 只有管理员可以查看管理员列表
CREATE POLICY "admin_users: admin only"
  ON public.admin_users FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_users
      WHERE id = auth.uid() AND is_active = TRUE
    )
  );

-- ── 2. admin_logs 操作日志表 ───────────────────────────────

CREATE TABLE IF NOT EXISTS public.admin_logs (
  id          BIGSERIAL PRIMARY KEY,
  admin_id    UUID REFERENCES public.admin_users(id) ON DELETE SET NULL,
  action      TEXT NOT NULL, -- login / approve_content / reject_content / ban_user / etc.
  target_type TEXT,          -- content / user / comment
  target_id   TEXT,
  details     JSONB DEFAULT '{}',
  ip_address  TEXT,
  user_agent  TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.admin_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admin_logs: admin read"
  ON public.admin_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_users
      WHERE id = auth.uid() AND is_active = TRUE
    )
  );

CREATE INDEX IF NOT EXISTS idx_admin_logs_admin_id
  ON public.admin_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_logs_created_at
  ON public.admin_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_logs_action
  ON public.admin_logs(action);

-- ── 3. comment_reports 评论举报表 ──────────────────────────

CREATE TABLE IF NOT EXISTS public.comment_reports (
  id          BIGSERIAL PRIMARY KEY,
  comment_id  UUID REFERENCES public.comments(id) ON DELETE CASCADE,
  reporter_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  reason      TEXT NOT NULL, -- spam / offensive / inappropriate / other
  description TEXT,
  status      TEXT DEFAULT 'pending', -- pending / reviewed / resolved
  reviewed_by UUID REFERENCES public.admin_users(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.comment_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "comment_reports: authenticated insert"
  ON public.comment_reports FOR INSERT
  WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "comment_reports: admin read"
  ON public.comment_reports FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_users
      WHERE id = auth.uid() AND is_active = TRUE
    )
  );

CREATE INDEX IF NOT EXISTS idx_comment_reports_status
  ON public.comment_reports(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_comment_reports_comment_id
  ON public.comment_reports(comment_id);

-- ── 4. 添加评论审核状态字段 ────────────────────────────────

DO $$ BEGIN
  CREATE TYPE comment_moderation_status AS ENUM ('pending', 'approved', 'rejected');
EXCEPTION WHEN duplicate_object THEN NULL;
END$$;

ALTER TABLE public.comments
  ADD COLUMN IF NOT EXISTS moderation_status comment_moderation_status DEFAULT 'approved';

ALTER TABLE public.comments
  ADD COLUMN IF NOT EXISTS is_flagged BOOLEAN DEFAULT FALSE;

-- ── 5. 添加用户封禁字段 ───────────────────────────────────

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_banned BOOLEAN DEFAULT FALSE;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS banned_at TIMESTAMPTZ;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS banned_reason TEXT;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS banned_by UUID REFERENCES public.admin_users(id);

-- ── 6. 更新 updated_at 触发器 ──────────────────────────────

CREATE TRIGGER admin_users_updated_at
  BEFORE UPDATE ON public.admin_users
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ── 7. 插入默认管理员（测试用） ────────────────────────────

-- 注意：实际部署时需要手动创建管理员账号
-- 这里仅用于开发测试

COMMENT ON TABLE public.admin_users IS '管理员表 - 需要手动添加管理员账号';
COMMENT ON TABLE public.admin_logs IS '管理员操作日志';
COMMENT ON TABLE public.comment_reports IS '评论举报记录';

COMMIT;
