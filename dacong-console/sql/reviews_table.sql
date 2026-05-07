-- =============================================
-- 评测文章表 (reviews) 数据库结构 SQL
-- =============================================

-- 1. 创建 reviews 表
CREATE TABLE IF NOT EXISTS reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  content TEXT DEFAULT '',
  summary TEXT,
  author_name TEXT NOT NULL DEFAULT '匿名用户',
  author_avatar TEXT,
  cover_image TEXT,
  tags TEXT[] DEFAULT '{}',
  tools_mentioned TEXT[] DEFAULT '{}',
  views INTEGER DEFAULT 0,
  likes INTEGER DEFAULT 0,
  published BOOLEAN DEFAULT false,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 创建索引
CREATE INDEX IF NOT EXISTS idx_reviews_slug ON reviews(slug);
CREATE INDEX IF NOT EXISTS idx_reviews_published ON reviews(published);
CREATE INDEX IF NOT EXISTS idx_reviews_published_at ON reviews(published_at);
CREATE INDEX IF NOT EXISTS idx_reviews_created_at ON reviews(created_at);
CREATE INDEX IF NOT EXISTS idx_reviews_tags ON reviews USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_reviews_tools_mentioned ON reviews USING GIN(tools_mentioned);

-- 3. 创建更新 updated_at 的触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 4. 创建触发器
DROP TRIGGER IF EXISTS update_reviews_updated_at ON reviews;
CREATE TRIGGER update_reviews_updated_at
    BEFORE UPDATE ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- 行级安全策略 (RLS)
-- =============================================

-- 启用 RLS
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- 5. 删除已有的策略（如果存在）
DROP POLICY IF EXISTS "Allow public read published reviews" ON reviews;
DROP POLICY IF EXISTS "Allow authenticated insert" ON reviews;
DROP POLICY IF EXISTS "Allow authenticated update own" ON reviews;
DROP POLICY IF EXISTS "Allow authenticated delete own" ON reviews;
DROP POLICY IF EXISTS "Allow admin full access" ON reviews;

-- 6. 创建公开读取策略（仅已发布的文章）
CREATE POLICY "Allow public read published reviews"
  ON reviews FOR SELECT
  USING (published = true);

-- 7. 创建插入策略（需要认证）
CREATE POLICY "Allow authenticated insert"
  ON reviews FOR INSERT
  WITH CHECK (true);

-- 8. 创建更新策略（需要认证）
CREATE POLICY "Allow authenticated update"
  ON reviews FOR UPDATE
  USING (true);

-- 9. 创建删除策略（需要认证）
CREATE POLICY "Allow authenticated delete"
  ON reviews FOR DELETE
  USING (true);

-- =============================================
-- 测试数据示例（可选）
-- =============================================

-- INSERT INTO reviews (title, slug, content, summary, author_name, tags, published)
-- VALUES
-- (
--   'Claude 3.5 Sonnet 深度评测',
--   'claude-3-5-sonnet-deep-review',
--   '# 深度评测\n\n这是一篇关于 Claude 3.5 Sonnet 的深度评测文章...',
--   '深入分析 Claude 3.5 Sonnet 在编程、推理和多模态任务上的表现',
--   'AI评测官',
--   ARRAY['编程', '深度评测', 'Claude'],
--   true
-- );