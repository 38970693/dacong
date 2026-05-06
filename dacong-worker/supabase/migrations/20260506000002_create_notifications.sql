-- Migration: Create notifications table
-- Description: 用户站内通知系统

CREATE TABLE IF NOT EXISTS notifications (
  -- 主键
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- 接收者
  user_id UUID NOT NULL,

  -- 通知类型
  type VARCHAR(30) NOT NULL CHECK (
    type IN (
      -- 系统通知
      'system.announcement', 'system.update', 'system.maintenance',
      -- 内容相关
      'content.reply', 'content.mention', 'content.like', 'content.favorite',
      -- 评测相关
      'review.published', 'review.commented', 'review.liked',
      -- 关注相关
      'follow.new_follower',
      -- 互动相关
      '互动.received_like', '互动.received_comment', '互动.received_reply'
    )
  ),

  -- 通知标题和内容
  title VARCHAR(200) NOT NULL,
  content TEXT NOT NULL,

  -- 跳转链接
  action_url TEXT,

  -- 关联目标
  target_type VARCHAR(50), -- post, review, comment, user
  target_id TEXT,

  -- 来源用户（可选，如点赞、评论等）
  source_user_id UUID,
  source_user_name VARCHAR(100),
  source_user_avatar TEXT,

  -- 状态
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMPTZ,

  -- 优先级
  priority VARCHAR(10) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),

  -- 过期时间（可选，用于限时通知）
  expires_at TIMESTAMPTZ,

  -- 元数据
  metadata JSONB, -- 存储额外信息如评论内容片段等

  -- 时间戳
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON notifications(user_id, is_read) WHERE NOT is_read;
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_target ON notifications(target_type, target_id) WHERE target_type IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_notifications_priority ON notifications(priority, created_at DESC) WHERE priority != 'low';
CREATE INDEX IF NOT EXISTS idx_notifications_expires ON notifications(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_notifications_source_user ON notifications(source_user_id, created_at DESC) WHERE source_user_id IS NOT NULL;

-- 注释
COMMENT ON TABLE notifications IS '用户通知表';
COMMENT ON COLUMN notifications.type IS '通知类型：system.*, content.*, review.*, 关注.*, 互动.*';
COMMENT ON COLUMN notifications.priority IS 'low=低优先级, normal=普通, high=高优先级, urgent=紧急';

-- RLS 策略
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- 用户只能查看自己的通知
CREATE POLICY "Allow users to view own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

-- 系统可以插入通知
CREATE POLICY "Allow service role to insert notifications"
  ON notifications FOR INSERT
  WITH CHECK (true);

-- 用户可以更新自己的通知（标记已读）
CREATE POLICY "Allow users to update own notifications"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id);

-- 不允许删除通知（软删除通过状态管理）
CREATE POLICY "Deny notification deletions"
  ON notifications FOR DELETE
  USING (false);

-- 创建更新 updated_at 的触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 创建触发器
CREATE TRIGGER update_notifications_updated_at
    BEFORE UPDATE ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 创建通知时自动清理过期通知（保留最近 1000 条）
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS TRIGGER AS $$
BEGIN
  -- 删除超过 1000 条的旧通知（每个用户）
  DELETE FROM notifications
  WHERE user_id = NEW.user_id
    AND id NOT IN (
      SELECT id FROM notifications
      WHERE user_id = NEW.user_id
      ORDER BY created_at DESC
      LIMIT 1000
    );
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER cleanup_notifications_on_insert
    AFTER INSERT ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION cleanup_old_notifications();