-- Migration: Create user_feedback table
-- Description: 收集用户对内容的反馈

CREATE TABLE user_feedback (
  -- 主键
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- 关联
  content_id UUID NOT NULL REFERENCES published_content(id) ON DELETE CASCADE,
  user_id UUID,

  -- 反馈内容
  is_helpful BOOLEAN NOT NULL,
  comment TEXT,

  -- 元数据
  user_agent TEXT,
  ip_address INET,

  -- 时间戳
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_user_feedback_content ON user_feedback(content_id, created_at DESC);
CREATE INDEX idx_user_feedback_user ON user_feedback(user_id, created_at DESC) WHERE user_id IS NOT NULL;
CREATE INDEX idx_user_feedback_helpful ON user_feedback(is_helpful, created_at DESC);

-- 唯一约束（防止重复反馈）
CREATE UNIQUE INDEX idx_user_feedback_unique_user ON user_feedback(content_id, user_id) WHERE user_id IS NOT NULL;
CREATE UNIQUE INDEX idx_user_feedback_unique_anon ON user_feedback(content_id, ip_address) WHERE user_id IS NULL;

-- 注释
COMMENT ON TABLE user_feedback IS '用户对内容的反馈';
COMMENT ON COLUMN user_feedback.is_helpful IS 'true=有用，false=无用';
