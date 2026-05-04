-- Migration: Add likes table and fix favorites table
-- Created: 2026-05-04

-- ============================================
-- PART 1: Create likes table
-- ============================================

CREATE TABLE IF NOT EXISTS likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_user_post_like UNIQUE (user_id, post_id)
);

CREATE INDEX IF NOT EXISTS idx_likes_user_id ON likes(user_id);
CREATE INDEX IF NOT EXISTS idx_likes_post_id ON likes(post_id);
CREATE INDEX IF NOT EXISTS idx_likes_created_at ON likes(created_at DESC);

COMMENT ON TABLE likes IS '用户点赞表';

ALTER TABLE likes ENABLE ROW LEVEL SECURITY;

-- Public read policy
DROP POLICY IF EXISTS "public.likes_select" ON likes;
CREATE POLICY "public.likes_select" ON likes FOR SELECT USING (true);

-- Authenticated insert/delete
DROP POLICY IF EXISTS "auth.likes_insert" ON likes;
CREATE POLICY "auth.likes_insert" ON likes FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "auth.likes_delete" ON likes;
CREATE POLICY "auth.likes_delete" ON likes FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- PART 2: Fix favorites table (add post_id if missing)
-- ============================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'favorites' AND column_name = 'post_id'
    ) THEN
        ALTER TABLE favorites ADD COLUMN post_id UUID REFERENCES posts(id) ON DELETE CASCADE;
    END IF;
END;
$$;

-- Add index for post_id if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes WHERE tablename = 'favorites' AND indexname = 'idx_favorites_post_id'
    ) THEN
        CREATE INDEX idx_favorites_post_id ON favorites(post_id);
    END IF;
END;
$$;

-- Update RLS for favorites
DROP POLICY IF EXISTS "public.favorites_select" ON favorites;
CREATE POLICY "public.favorites_select" ON favorites FOR SELECT USING (true);

DROP POLICY IF EXISTS "auth.favorites_insert" ON favorites;
CREATE POLICY "auth.favorites_insert" ON favorites FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "auth.favorites_delete" ON favorites;
CREATE POLICY "auth.favorites_delete" ON favorites FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- PART 3: Create triggers for count updates
-- ============================================

-- Function to update post likes count
CREATE OR REPLACE FUNCTION update_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE posts SET likes = COALESCE(likes, 0) + 1 WHERE id = NEW.post_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE posts SET likes = GREATEST(0, COALESCE(likes, 0) - 1) WHERE id = OLD.post_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_like_insert ON likes;
DROP TRIGGER IF EXISTS on_like_delete ON likes;
CREATE TRIGGER on_like_insert AFTER INSERT ON likes FOR EACH ROW EXECUTE FUNCTION update_post_likes_count();
CREATE TRIGGER on_like_delete AFTER DELETE ON likes FOR EACH ROW EXECUTE FUNCTION update_post_likes_count();

-- Function to update post favorites count
CREATE OR REPLACE FUNCTION update_post_favorites_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE posts SET favorites_count = COALESCE(favorites_count, 0) + 1 WHERE id = NEW.post_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE posts SET favorites_count = GREATEST(0, COALESCE(favorites_count, 0) - 1) WHERE id = OLD.post_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_favorite_insert ON favorites;
DROP TRIGGER IF EXISTS on_favorite_delete ON favorites;
CREATE TRIGGER on_favorite_insert AFTER INSERT ON favorites FOR EACH ROW EXECUTE FUNCTION update_post_favorites_count();
CREATE TRIGGER on_favorite_delete AFTER DELETE ON favorites FOR EACH ROW EXECUTE FUNCTION update_post_favorites_count();
