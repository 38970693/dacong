-- Migration: Create feedbacks table
-- Description: 收集用户的问题反馈、功能建议、商务合作等

CREATE TABLE IF NOT EXISTS feedbacks (
  -- 主键
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- 反馈类型
  type VARCHAR(20) NOT NULL CHECK (type IN ('suggestion', 'bug', 'business', 'other')),

  -- 反馈内容
  content TEXT NOT NULL CHECK (char_length(content) >= 10 AND char_length(content) <= 2000),

  -- 联系方式
  contact TEXT,

  -- 用户信息（可选）
  user_id UUID,
  user_email TEXT,

  -- 状态
  status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'archived')),

  -- 元数据
  user_agent TEXT,
  ip_address INET,

  -- 时间戳
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_feedbacks_type ON feedbacks(type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_feedbacks_status ON feedbacks(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_feedbacks_user ON feedbacks(user_id, created_at DESC) WHERE user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_feedbacks_created ON feedbacks(created_at DESC);

-- 注释
COMMENT ON TABLE feedbacks IS '用户反馈和建议';
COMMENT ON COLUMN feedbacks.type IS 'suggestion=功能建议, bug=问题反馈, business=商务合作, other=其他';
COMMENT ON COLUMN feedbacks.status IS 'pending=待处理, reviewed=已查看, resolved=已解决, archived=已归档';

-- RLS 策略
ALTER TABLE feedbacks ENABLE ROW LEVEL SECURITY;

-- 任何人都可以提交反馈
CREATE POLICY "Allow anonymous feedback submission"
  ON feedbacks FOR INSERT
  WITH CHECK (true);

-- 只有管理员可以查看和更新反馈
CREATE POLICY "Allow admins to view feedbacks"
  ON feedbacks FOR SELECT
  USING (true);

CREATE POLICY "Allow admins to update feedbacks"
  ON feedbacks FOR UPDATE
  USING (true);
