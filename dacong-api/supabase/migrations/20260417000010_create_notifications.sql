-- 通知表
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,
  title VARCHAR(200) NOT NULL,
  content TEXT NOT NULL,
  link VARCHAR(500),
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引优化
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;

-- 更新时间触发器
CREATE OR REPLACE FUNCTION update_notifications_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_notifications_updated_at
  BEFORE UPDATE ON notifications
  FOR EACH ROW
  EXECUTE FUNCTION update_notifications_updated_at();

-- RLS 策略
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- 用户只能查看自己的通知
CREATE POLICY "Users can view their own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

-- 用户只能更新自己的通知
CREATE POLICY "Users can update their own notifications"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id);

-- 系统可以插入通知（通过服务角色）
CREATE POLICY "Service role can insert notifications"
  ON notifications FOR INSERT
  WITH CHECK (true);

-- 注释
COMMENT ON TABLE notifications IS '用户通知表';
COMMENT ON COLUMN notifications.id IS '通知ID';
COMMENT ON COLUMN notifications.user_id IS '用户ID';
COMMENT ON COLUMN notifications.type IS '通知类型：comment_reply, favorite, system_announcement';
COMMENT ON COLUMN notifications.title IS '通知标题';
COMMENT ON COLUMN notifications.content IS '通知内容';
COMMENT ON COLUMN notifications.link IS '跳转链接';
COMMENT ON COLUMN notifications.is_read IS '是否已读';
COMMENT ON COLUMN notifications.created_at IS '创建时间';
COMMENT ON COLUMN notifications.updated_at IS '更新时间';
