-- =============================================
-- dacong 标签系统数据库脚本
-- 执行方式: 在 Supabase SQL Editor 中执行
-- =============================================

-- 1. 创建标签表
CREATE TABLE IF NOT EXISTS tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  color TEXT DEFAULT '#3B82F6',
  post_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 创建文章-标签关联表
CREATE TABLE IF NOT EXISTS post_tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id TEXT NOT NULL,
  tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, tag_id)
);

-- 3. 创建索引提升查询性能
CREATE INDEX IF NOT EXISTS idx_post_tags_post_id ON post_tags(post_id);
CREATE INDEX IF NOT EXISTS idx_post_tags_tag_id ON post_tags(tag_id);
CREATE INDEX IF NOT EXISTS idx_tags_slug ON tags(slug);
CREATE INDEX IF NOT EXISTS idx_tags_post_count ON tags(post_count DESC);

-- 4. 自动更新 post_count 触发器函数
CREATE OR REPLACE FUNCTION update_tag_post_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE tags
    SET post_count = (
      SELECT COUNT(*) FROM post_tags WHERE tag_id = NEW.tag_id
    ),
    updated_at = NOW()
    WHERE id = NEW.tag_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE tags
    SET post_count = (
      SELECT COUNT(*) FROM post_tags WHERE tag_id = OLD.tag_id
    ),
    updated_at = NOW()
    WHERE id = OLD.tag_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 5. 创建触发器
DROP TRIGGER IF EXISTS trigger_update_tag_post_count ON post_tags;
CREATE TRIGGER trigger_update_tag_post_count
AFTER INSERT OR DELETE ON post_tags
FOR EACH ROW EXECUTE FUNCTION update_tag_post_count();

-- =============================================
-- 初始数据（可选）
-- =============================================

-- 插入一些默认标签
INSERT INTO tags (name, slug, color) VALUES
  ('AI', 'ai', '#3B82F6'),
  ('编程', 'programming', '#10B981'),
  ('创意写作', 'creative-writing', '#EC4899'),
  ('数学推理', 'math', '#F59E0B'),
  ('多模态', 'multimodal', '#8B5CF6'),
  ('RAG', 'rag', '#6366F1'),
  ('开源', 'open-source', '#22C55E'),
  ('中文', 'chinese', '#EF4444')
ON CONFLICT (name) DO NOTHING;

-- =============================================
-- 验证查询
-- =============================================

-- SELECT * FROM tags ORDER BY post_count DESC;
-- SELECT * FROM post_tags LIMIT 10;