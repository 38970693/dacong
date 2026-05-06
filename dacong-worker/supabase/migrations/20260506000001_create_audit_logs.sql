-- Migration: Create audit_logs table
-- Description: 管理后台审计日志，记录所有用户操作

CREATE TABLE IF NOT EXISTS audit_logs (
  -- 主键
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- 操作者信息
  user_id UUID,
  user_email TEXT,
  user_ip INET,
  user_agent TEXT,

  -- 操作类型 (CRUD + 认证 + 管理)
  action VARCHAR(50) NOT NULL CHECK (
    action IN (
      -- 认证类
      'auth.login', 'auth.logout', 'auth.register', 'auth.oauth',
      -- 内容管理
      'content.create', 'content.read', 'content.update', 'content.delete',
      -- 评测管理
      'review.create', 'review.update', 'review.delete', 'review.publish',
      -- 收藏/点赞
      'favorite.add', 'favorite.remove', 'like.add', 'like.remove',
      -- 反馈处理
      'feedback.review', 'feedback.resolve', 'feedback.archive',
      -- 系统设置
      'settings.update', 'settings.reset',
      -- 其他
      'api.access', 'export.data', 'import.data'
    )
  ),

  -- 操作目标
  target_type VARCHAR(50), -- post, review, user, feedback, settings
  target_id TEXT,

  -- 操作详情
  detail JSONB, -- 存储额外信息如变更前后数据
  result VARCHAR(20) DEFAULT 'success' CHECK (result IN ('success', 'failure', 'partial')),

  -- 请求信息
  request_method VARCHAR(10),
  request_path TEXT,
  request_params JSONB,
  response_code INTEGER,

  -- 时间戳
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_logs_user ON audit_logs(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_logs_action ON audit_logs(action, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_logs_target ON audit_logs(target_type, target_id) WHERE target_type IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_logs_result ON audit_logs(result, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_logs_created ON audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_logs_ip ON audit_logs(user_ip, created_at DESC) WHERE user_ip IS NOT NULL;

-- 注释
COMMENT ON TABLE audit_logs IS '审计日志表';
COMMENT ON COLUMN audit_logs.action IS '操作类型，如 auth.login, content.create, review.update';
COMMENT ON COLUMN audit_logs.detail IS 'JSON格式的额外信息，如 {old: {...}, new: {...}}';

-- RLS 策略
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- 任何人都可以插入日志（通常由服务端插入）
CREATE POLICY "Allow anonymous log insertion"
  ON audit_logs FOR INSERT
  WITH CHECK (true);

-- 只有管理员可以查看日志
CREATE POLICY "Allow admins to view logs"
  ON audit_logs FOR SELECT
  USING (
    -- TODO: 需要通过 RLS 检查用户是否是管理员
    true
  );

-- 日志不支持更新和删除
CREATE POLICY "Deny log updates"
  ON audit_logs FOR UPDATE
  USING (false);

CREATE POLICY "Deny log deletions"
  ON audit_logs FOR DELETE
  USING (false);