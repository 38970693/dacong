-- ============================================
-- 完整的管理后台数据库设置脚本
-- ============================================

BEGIN;

-- ── 1. 创建 admin_users 表 ────────────────────────────────

CREATE TABLE IF NOT EXISTS public.admin_users (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email       TEXT NOT NULL UNIQUE,
  role        TEXT NOT NULL DEFAULT 'moderator',
  permissions JSONB DEFAULT '{}',
  is_active   BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_users: admin only" ON public.admin_users;
CREATE POLICY "admin_users: admin only"
  ON public.admin_users FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_users
      WHERE id = auth.uid() AND is_active = TRUE
    )
  );

-- ── 2. 创建 admin_logs 表 ───────────────────────────────

CREATE TABLE IF NOT EXISTS public.admin_logs (
  id          BIGSERIAL PRIMARY KEY,
  admin_id    UUID REFERENCES public.admin_users(id) ON DELETE SET NULL,
  action      TEXT NOT NULL,
  target_type TEXT,
  target_id   TEXT,
  details     JSONB DEFAULT '{}',
  ip_address  TEXT,
  user_agent  TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.admin_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_logs: admin read" ON public.admin_logs;
CREATE POLICY "admin_logs: admin read"
  ON public.admin_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_users
      WHERE id = auth.uid() AND is_active = TRUE
    )
  );

CREATE INDEX IF NOT EXISTS idx_admin_logs_admin_id ON public.admin_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_logs_created_at ON public.admin_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_logs_action ON public.admin_logs(action);

-- ── 3. 创建 comment_reports 表 ──────────────────────────

CREATE TABLE IF NOT EXISTS public.comment_reports (
  id          BIGSERIAL PRIMARY KEY,
  comment_id  UUID,
  reporter_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  reason      TEXT NOT NULL,
  description TEXT,
  status      TEXT DEFAULT 'pending',
  reviewed_by UUID REFERENCES public.admin_users(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.comment_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "comment_reports: authenticated insert" ON public.comment_reports;
CREATE POLICY "comment_reports: authenticated insert"
  ON public.comment_reports FOR INSERT
  WITH CHECK (auth.uid() = reporter_id);

DROP POLICY IF EXISTS "comment_reports: admin read" ON public.comment_reports;
CREATE POLICY "comment_reports: admin read"
  ON public.comment_reports FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_users
      WHERE id = auth.uid() AND is_active = TRUE
    )
  );

CREATE INDEX IF NOT EXISTS idx_comment_reports_status ON public.comment_reports(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_comment_reports_comment_id ON public.comment_reports(comment_id);

COMMIT;
