-- 评论系统数据库迁移
-- 创建 comments 和 comment_likes 表

-- 1. 创建 comments 表
CREATE TABLE IF NOT EXISTS comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id UUID NOT NULL REFERENCES published_content(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  parent_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  content TEXT NOT NULL CHECK (char_length(content) >= 1 AND char_length(content) <= 2000),
  likes_count INT DEFAULT 0 CHECK (likes_count >= 0),
  reply_count INT DEFAULT 0 CHECK (reply_count >= 0),
  is_deleted BOOLEAN DEFAULT FALSE,
  is_reported BOOLEAN DEFAULT FALSE,
  moderation_status TEXT DEFAULT 'approved' CHECK (moderation_status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 创建 comment_likes 表
CREATE TABLE IF NOT EXISTS comment_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  comment_id UUID NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(comment_id, user_id)
);

-- 3. 创建索引
CREATE INDEX idx_comments_content_id ON comments(content_id, created_at DESC) WHERE NOT is_deleted;
CREATE INDEX idx_comments_parent_id ON comments(parent_id, created_at DESC) WHERE parent_id IS NOT NULL AND NOT is_deleted;
CREATE INDEX idx_comments_user_id ON comments(user_id, created_at DESC);
CREATE INDEX idx_comments_moderation ON comments(moderation_status, created_at DESC) WHERE moderation_status = 'pending';
CREATE INDEX idx_comment_likes_comment_id ON comment_likes(comment_id, created_at DESC);
CREATE INDEX idx_comment_likes_user_id ON comment_likes(user_id, created_at DESC);

-- 4. 创建触发器：自动更新 updated_at
CREATE TRIGGER update_comments_updated_at
BEFORE UPDATE ON comments
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 5. 创建触发器：更新 likes_count
CREATE OR REPLACE FUNCTION update_comment_likes_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE comments
    SET likes_count = likes_count + 1
    WHERE id = NEW.comment_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE comments
    SET likes_count = GREATEST(0, likes_count - 1)
    WHERE id = OLD.comment_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_comment_likes_count_on_insert
AFTER INSERT ON comment_likes
FOR EACH ROW
EXECUTE FUNCTION update_comment_likes_count();

CREATE TRIGGER update_comment_likes_count_on_delete
AFTER DELETE ON comment_likes
FOR EACH ROW
EXECUTE FUNCTION update_comment_likes_count();

-- 6. 创建触发器：更新 reply_count
CREATE OR REPLACE FUNCTION update_comment_reply_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.parent_id IS NOT NULL THEN
    UPDATE comments
    SET reply_count = reply_count + 1
    WHERE id = NEW.parent_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' AND OLD.parent_id IS NOT NULL THEN
    UPDATE comments
    SET reply_count = GREATEST(0, reply_count - 1)
    WHERE id = OLD.parent_id;
    RETURN OLD;
  ELSIF TG_OP = 'UPDATE' AND OLD.is_deleted = FALSE AND NEW.is_deleted = TRUE AND NEW.parent_id IS NOT NULL THEN
    UPDATE comments
    SET reply_count = GREATEST(0, reply_count - 1)
    WHERE id = NEW.parent_id;
    RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_comment_reply_count_on_insert
AFTER INSERT ON comments
FOR EACH ROW
EXECUTE FUNCTION update_comment_reply_count();

CREATE TRIGGER update_comment_reply_count_on_delete
AFTER DELETE ON comments
FOR EACH ROW
EXECUTE FUNCTION update_comment_reply_count();

CREATE TRIGGER update_comment_reply_count_on_update
AFTER UPDATE ON comments
FOR EACH ROW
WHEN (OLD.is_deleted IS DISTINCT FROM NEW.is_deleted)
EXECUTE FUNCTION update_comment_reply_count();

-- 7. 启用 RLS
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE comment_likes ENABLE ROW LEVEL SECURITY;

-- 8. RLS 策略：comments
-- 所有人可以查看未删除的已审核评论
CREATE POLICY "Anyone can view approved comments"
ON comments FOR SELECT
USING (NOT is_deleted AND moderation_status = 'approved');

-- 认证用户可以创建评论
CREATE POLICY "Authenticated users can create comments"
ON comments FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- 用户可以更新自己的评论（仅限内容和is_deleted）
CREATE POLICY "Users can update own comments"
ON comments FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 用户可以删除自己的评论
CREATE POLICY "Users can delete own comments"
ON comments FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- 管理员可以查看所有评论
CREATE POLICY "Admins can view all comments"
ON comments FOR SELECT
TO authenticated
USING (auth.jwt() ->> 'role' = 'admin');

-- 管理员可以修改所有评论
CREATE POLICY "Admins can modify all comments"
ON comments FOR ALL
TO authenticated
USING (auth.jwt() ->> 'role' = 'admin')
WITH CHECK (auth.jwt() ->> 'role' = 'admin');

-- 9. RLS 策略：comment_likes
-- 所有人可以查看点赞
CREATE POLICY "Anyone can view comment likes"
ON comment_likes FOR SELECT
USING (true);

-- 认证用户可以点赞
CREATE POLICY "Authenticated users can like comments"
ON comment_likes FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- 用户可以取消自己的点赞
CREATE POLICY "Users can unlike own likes"
ON comment_likes FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- 10. 注释
COMMENT ON TABLE comments IS '评论表';
COMMENT ON COLUMN comments.content_id IS '关联的内容ID';
COMMENT ON COLUMN comments.user_id IS '评论用户ID';
COMMENT ON COLUMN comments.parent_id IS '父评论ID（回复时使用）';
COMMENT ON COLUMN comments.content IS '评论内容（1-2000字符）';
COMMENT ON COLUMN comments.likes_count IS '点赞数';
COMMENT ON COLUMN comments.reply_count IS '回复数';
COMMENT ON COLUMN comments.is_deleted IS '是否已删除（软删除）';
COMMENT ON COLUMN comments.is_reported IS '是否被举报';
COMMENT ON COLUMN comments.moderation_status IS '审核状态：pending/approved/rejected';

COMMENT ON TABLE comment_likes IS '评论点赞表';
COMMENT ON COLUMN comment_likes.comment_id IS '评论ID';
COMMENT ON COLUMN comment_likes.user_id IS '点赞用户ID';
