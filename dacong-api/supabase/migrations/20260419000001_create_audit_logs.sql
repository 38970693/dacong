-- Migration: Create audit_logs table
-- Description: 审计日志系统，记录所有管理员操作

-- ============================================
-- audit_logs 表 - 审计日志
-- ============================================
CREATE TABLE IF NOT EXISTS audit_logs (
  -- 主键
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- 操作用户
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,

  -- 操作信息
  action VARCHAR(100) NOT NULL,
  resource VARCHAR(100) NOT NULL,
  resource_id TEXT,

  -- 详细信息
  details JSONB DEFAULT '{}',

  -- 请求信息
  ip_address INET,
  user_agent TEXT,

  -- 操作结果
  status VARCHAR(20) CHECK (status IN ('success', 'failure', 'error')),
  error_message TEXT,

  -- 时间戳
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id, created_at DESC);
CREATE INDEX idx_audit_logs_action ON audit_logs(action, created_at DESC);
CREATE INDEX idx_audit_logs_resource ON audit_logs(resource, resource_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);
CREATE INDEX idx_audit_logs_status ON audit_logs(status) WHERE status != 'success';

-- 注释
COMMENT ON TABLE audit_logs IS '审计日志表，记录所有重要操作';
COMMENT ON COLUMN audit_logs.user_id IS '操作用户ID';
COMMENT ON COLUMN audit_logs.action IS '操作类型：create/update/delete/approve/reject/ban/unban等';
COMMENT ON COLUMN audit_logs.resource IS '资源类型：user/content/comment等';
COMMENT ON COLUMN audit_logs.resource_id IS '资源ID';
COMMENT ON COLUMN audit_logs.details IS '操作详细信息（JSON格式）';
COMMENT ON COLUMN audit_logs.ip_address IS '客户端IP地址';
COMMENT ON COLUMN audit_logs.user_agent IS '客户端User-Agent';
COMMENT ON COLUMN audit_logs.status IS '操作状态：success/failure/error';

-- ============================================
-- RLS 策略
-- ============================================
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- 只有管理员可以查看审计日志
CREATE POLICY "Only admins can view audit logs"
  ON audit_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
      AND user_roles.role IN ('admin', 'moderator')
      AND user_roles.is_active = true
    )
  );

-- 系统可以插入审计日志
CREATE POLICY "System can insert audit logs"
  ON audit_logs FOR INSERT
  WITH CHECK (true);

-- ============================================
-- 辅助函数：记录审计日志
-- ============================================
CREATE OR REPLACE FUNCTION log_audit(
  p_user_id UUID,
  p_action VARCHAR,
  p_resource VARCHAR,
  p_resource_id TEXT DEFAULT NULL,
  p_details JSONB DEFAULT '{}',
  p_ip_address TEXT DEFAULT NULL,
  p_user_agent TEXT DEFAULT NULL,
  p_status VARCHAR DEFAULT 'success',
  p_error_message TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_log_id UUID;
BEGIN
  INSERT INTO audit_logs (
    user_id,
    action,
    resource,
    resource_id,
    details,
    ip_address,
    user_agent,
    status,
    error_message
  ) VALUES (
    p_user_id,
    p_action,
    p_resource,
    p_resource_id,
    p_details,
    p_ip_address::INET,
    p_user_agent,
    p_status,
    p_error_message
  )
  RETURNING id INTO v_log_id;

  RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION log_audit IS '记录审计日志的辅助函数';
