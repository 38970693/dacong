-- 创建 reports 表（举报/投诉功能）

CREATE TABLE IF NOT EXISTS public.reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- 被举报的内容
  content_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
  comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,

  -- 举报人
  reporter_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,

  -- 举报信息
  reason TEXT NOT NULL,
  description TEXT,
  category TEXT, -- 'spam', 'abuse', 'inappropriate', 'other'

  -- 处理状态
  status TEXT DEFAULT 'pending', -- 'pending', 'reviewing', 'resolved', 'rejected'

  -- 处理信息
  reviewed_by UUID REFERENCES auth.users(id),
  reviewed_at TIMESTAMPTZ,
  admin_note TEXT,

  -- 时间戳
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- 约束：必须举报内容或评论之一
  CONSTRAINT report_target_check CHECK (
    (content_id IS NOT NULL AND comment_id IS NULL) OR
    (content_id IS NULL AND comment_id IS NOT NULL)
  )
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_reports_status ON public.reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_content_id ON public.reports(content_id);
CREATE INDEX IF NOT EXISTS idx_reports_comment_id ON public.reports(comment_id);
CREATE INDEX IF NOT EXISTS idx_reports_reporter_id ON public.reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON public.reports(created_at DESC);

-- 启用 RLS
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- RLS 策略：管理员可以查看所有举报
CREATE POLICY "Admins can view all reports"
  ON public.reports
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

-- RLS 策略：用户可以创建举报
CREATE POLICY "Users can create reports"
  ON public.reports
  FOR INSERT
  TO authenticated
  WITH CHECK (reporter_id = auth.uid());

-- RLS 策略：管理员可以更新举报状态
CREATE POLICY "Admins can update reports"
  ON public.reports
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

-- 创建更新时间触发器
CREATE OR REPLACE FUNCTION update_reports_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER reports_updated_at
  BEFORE UPDATE ON public.reports
  FOR EACH ROW
  EXECUTE FUNCTION update_reports_updated_at();

-- 插入一些测试数据（可选）
-- INSERT INTO public.reports (content_id, reporter_id, reason, category, description)
-- VALUES
--   (NULL, NULL, 'Test report', 'spam', 'This is a test report');
