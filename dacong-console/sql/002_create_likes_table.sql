-- ============================================
-- 创建点赞表 (likes)
-- ============================================
-- 用于存储用户点赞的帖子

-- 1. 创建点赞表
CREATE TABLE IF NOT EXISTS likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- 防止重复点赞
    CONSTRAINT unique_user_post_like UNIQUE (user_id, post_id)
);

-- 2. 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_likes_user_id ON likes(user_id);
CREATE INDEX IF NOT EXISTS idx_likes_post_id ON likes(post_id);
CREATE INDEX IF NOT EXISTS idx_likes_created_at ON likes(created_at DESC);

-- 3. 添加注释
COMMENT ON TABLE likes IS '用户点赞表';
COMMENT ON COLUMN likes.user_id IS '用户ID (关联 auth.users)';
COMMENT ON COLUMN likes.post_id IS '帖子ID (关联 posts)';
COMMENT ON COLUMN likes.created_at IS '点赞时间';

-- 4. 启用 RLS (Row Level Security)
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;

-- 5. 创建 RLS 策略
-- 用户只能查看自己的点赞
CREATE POLICY "Users can view their own likes"
    ON likes FOR SELECT
    USING (auth.uid() = user_id);

-- 用户只能创建自己的点赞
CREATE POLICY "Users can create their own likes"
    ON likes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- 用户只能删除自己的点赞
CREATE POLICY "Users can delete their own likes"
    ON likes FOR DELETE
    USING (auth.uid() = user_id);

-- 6. 创建更新策略
CREATE POLICY "Users can only update own likes"
    ON likes FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);