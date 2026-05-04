-- ============================================
-- 创建收藏表 (favorites)
-- ============================================
-- 用于存储用户收藏的帖子

-- 1. 创建收藏表
CREATE TABLE IF NOT EXISTS favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- 防止重复收藏
    CONSTRAINT unique_user_post_favorite UNIQUE (user_id, post_id)
);

-- 2. 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_post_id ON favorites(post_id);
CREATE INDEX IF NOT EXISTS idx_favorites_created_at ON favorites(created_at DESC);

-- 3. 添加注释
COMMENT ON TABLE favorites IS '用户收藏表';
COMMENT ON COLUMN favorites.user_id IS '用户ID (关联 auth.users)';
COMMENT ON COLUMN favorites.post_id IS '帖子ID (关联 posts)';
COMMENT ON COLUMN favorites.created_at IS '收藏时间';

-- 4. 启用 RLS (Row Level Security)
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

-- 5. 创建 RLS 策略
-- 用户只能查看自己的收藏
CREATE POLICY "Users can view their own favorites"
    ON favorites FOR SELECT
    USING (auth.uid() = user_id);

-- 用户只能创建自己的收藏
CREATE POLICY "Users can create their own favorites"
    ON favorites FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- 用户只能删除自己的收藏
CREATE POLICY "Users can delete their own favorites"
    ON favorites FOR DELETE
    USING (auth.uid() = user_id);

-- 6. 创建更新和删除的限制策略（防止更新其他用户数据）
CREATE POLICY "Users can only update own favorites"
    ON favorites FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);