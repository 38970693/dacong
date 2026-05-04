-- ============================================
-- DaCong 数据库 Migration
-- ============================================
-- 在 Supabase SQL Editor 中完整执行此文件
-- 执行顺序：001 创建收藏表 → 002 创建点赞表

-- ============================================
-- PART 1: 收藏表 (favorites)
-- ============================================

-- 1. 创建收藏表（如果不存在）
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
DROP POLICY IF EXISTS "Users can view their own favorites" ON favorites;
CREATE POLICY "Users can view their own favorites"
    ON favorites FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create their own favorites" ON favorites;
CREATE POLICY "Users can create their own favorites"
    ON favorites FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own favorites" ON favorites;
CREATE POLICY "Users can delete their own favorites"
    ON favorites FOR DELETE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can only update own favorites" ON favorites;
CREATE POLICY "Users can only update own favorites"
    ON favorites FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);


-- ============================================
-- PART 2: 点赞表 (likes)
-- ============================================

-- 1. 创建点赞表（如果不存在）
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
DROP POLICY IF EXISTS "Users can view their own likes" ON likes;
CREATE POLICY "Users can view their own likes"
    ON likes FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create their own likes" ON likes;
CREATE POLICY "Users can create their own likes"
    ON likes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own likes" ON likes;
CREATE POLICY "Users can delete their own likes"
    ON likes FOR DELETE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can only update own likes" ON likes;
CREATE POLICY "Users can only update own likes"
    ON likes FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);


-- ============================================
-- PART 3: 创建触发器 - 自动更新 posts 表的统计字段
-- ============================================

-- 创建函数：更新帖子点赞数
CREATE OR REPLACE FUNCTION update_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE posts SET likes = likes + 1 WHERE id = NEW.post_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE posts SET likes = likes - 1 WHERE id = OLD.post_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 删除旧触发器（如果存在）
DROP TRIGGER IF EXISTS on_like_insert ON likes;
DROP TRIGGER IF EXISTS on_like_delete ON likes;

-- 创建触发器
CREATE TRIGGER on_like_insert
    AFTER INSERT ON likes
    FOR EACH ROW
    EXECUTE FUNCTION update_post_likes_count();

CREATE TRIGGER on_like_delete
    AFTER DELETE ON likes
    FOR EACH ROW
    EXECUTE FUNCTION update_post_likes_count();


-- 创建函数：更新帖子收藏数
CREATE OR REPLACE FUNCTION update_post_favorites_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE posts SET favorites_count = favorites_count + 1 WHERE id = NEW.post_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE posts SET favorites_count = favorites_count - 1 WHERE id = OLD.post_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 删除旧触发器（如果存在）
DROP TRIGGER IF EXISTS on_favorite_insert ON favorites;
DROP TRIGGER IF EXISTS on_favorite_delete ON favorites;

-- 创建触发器
CREATE TRIGGER on_favorite_insert
    AFTER INSERT ON favorites
    FOR EACH ROW
    EXECUTE FUNCTION update_post_favorites_count();

CREATE TRIGGER on_favorite_delete
    AFTER DELETE ON favorites
    FOR EACH ROW
    EXECUTE FUNCTION update_post_favorites_count();


-- ============================================
-- 验证查询
-- ============================================
SELECT 'Tables created successfully!' as status;
SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename IN ('favorites', 'likes');