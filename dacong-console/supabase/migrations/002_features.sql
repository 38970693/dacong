-- DaCong v2.0 数据库扩展
-- 榜单、评测、标签、搜索功能

-- =============================================
-- 1. AI 模型榜单表
-- =============================================
CREATE TABLE IF NOT EXISTS models (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  provider TEXT NOT NULL,
  category TEXT DEFAULT '综合',
  description TEXT,
  icon TEXT,
  score DECIMAL(5,2) DEFAULT 0,
  change INTEGER DEFAULT 0,
  context_window INTEGER,
  pricing_input DECIMAL(10,2),
  pricing_output DECIMAL(10,2),
  website_url TEXT,
  api_endpoint TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 2. 评测文章表
-- =============================================
CREATE TABLE IF NOT EXISTS reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  model_id UUID REFERENCES models(id) ON DELETE SET NULL,
  model_name TEXT NOT NULL,
  title TEXT NOT NULL,
  summary TEXT,
  content TEXT NOT NULL,
  reviewer TEXT NOT NULL,
  rating DECIMAL(2,1) DEFAULT 0,
  review_type TEXT DEFAULT '深度评测' CHECK (review_type IN ('深度评测', '对比测试', '专项测试', '用户评测')),
  tags TEXT[],
  likes INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  is_featured BOOLEAN DEFAULT false,
  status TEXT DEFAULT 'published' CHECK (status IN ('draft', 'published', 'archived')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 3. 标签表
-- =============================================
CREATE TABLE IF NOT EXISTS tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  slug TEXT NOT NULL UNIQUE,
  color TEXT DEFAULT '#666666',
  post_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 4. 帖子-标签关联表
-- =============================================
CREATE TABLE IF NOT EXISTS post_tags (
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (post_id, tag_id)
);

-- =============================================
-- 5. 模型-标签关联表
-- =============================================
CREATE TABLE IF NOT EXISTS model_tags (
  model_id UUID REFERENCES models(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (model_id, tag_id)
);

-- =============================================
-- 6. 用户收藏表
-- =============================================
CREATE TABLE IF NOT EXISTS favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  target_type TEXT NOT NULL CHECK (target_type IN ('post', 'review', 'model')),
  target_id UUID NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, target_type, target_id)
);

-- =============================================
-- 7. 评论表
-- =============================================
CREATE TABLE IF NOT EXISTS comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  target_type TEXT NOT NULL CHECK (target_type IN ('post', 'review')),
  target_id UUID NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  parent_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  likes INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 8. 用户关注表
-- =============================================
CREATE TABLE IF NOT EXISTS follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  following_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(follower_id, following_id)
);

-- =============================================
-- 索引
-- =============================================
CREATE INDEX IF NOT EXISTS idx_models_category ON models(category);
CREATE INDEX IF NOT EXISTS idx_models_score ON models(score DESC);
CREATE INDEX IF NOT EXISTS idx_reviews_model_id ON reviews(model_id);
CREATE INDEX IF NOT EXISTS idx_reviews_rating ON reviews(rating DESC);
CREATE INDEX IF NOT EXISTS idx_reviews_created_at ON reviews(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_comments_target ON comments(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_favorites_user ON favorites(user_id, target_type);
CREATE INDEX IF NOT EXISTS idx_follows_follower ON follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON follows(following_id);

-- =============================================
-- 全文搜索索引
-- 注意：中文全文搜索需要 pg_jieba 扩展
-- 这里使用 simple 配置作为基础
-- =============================================
-- 注意：PostgreSQL 不支持 CREATE TEXT SEARCH CONFIGURATION IF NOT EXISTS
-- 如需中文分词，请先安装 pg_jieba 扩展，然后手动运行：
-- CREATE TEXT SEARCH CONFIGURATION chinese_zh (COPY = simple);
-- ALTER TEXT SEARCH CONFIGURATION chinese_zh ADD MAPPING FOR word WITH simple;

-- 使用 simple 配置创建索引（适用于英文或简单场景）
CREATE INDEX IF NOT EXISTS idx_posts_title_search ON posts USING gin(to_tsvector('simple', coalesce(title, '')));
CREATE INDEX IF NOT EXISTS idx_posts_content_search ON posts USING gin(to_tsvector('simple', coalesce(content, '')));
CREATE INDEX IF NOT EXISTS idx_reviews_title_search ON reviews USING gin(to_tsvector('simple', coalesce(title, '')));
CREATE INDEX IF NOT EXISTS idx_reviews_content_search ON reviews USING gin(to_tsvector('simple', coalesce(content, '')));

-- =============================================
-- 触发器：更新 updated_at
-- =============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER update_models_updated_at
  BEFORE UPDATE ON models
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE TRIGGER update_reviews_updated_at
  BEFORE UPDATE ON reviews
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE TRIGGER update_comments_updated_at
  BEFORE UPDATE ON comments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- 触发器：更新 tag 计数
-- =============================================
CREATE OR REPLACE FUNCTION update_tag_post_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE tags SET post_count = post_count + 1 WHERE id = NEW.tag_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE tags SET post_count = post_count - 1 WHERE id = OLD.tag_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_post_tags_count ON post_tags;
CREATE TRIGGER update_post_tags_count
  AFTER INSERT OR DELETE ON post_tags
  FOR EACH ROW
  EXECUTE FUNCTION update_tag_post_count();

-- =============================================
-- RLS 策略
-- =============================================
ALTER TABLE models ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE model_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;

-- models: 所有人可读，admin 可写
DROP POLICY IF EXISTS "models_public_read" ON models;
CREATE POLICY "models_public_read" ON models FOR SELECT TO public USING (is_active = true);
DROP POLICY IF EXISTS "models_admin_write" ON models;
CREATE POLICY "models_admin_write" ON models FOR ALL TO service_role USING (true);

-- reviews: 所有人可读，admin 可写
DROP POLICY IF EXISTS "reviews_public_read" ON reviews;
CREATE POLICY "reviews_public_read" ON reviews FOR SELECT TO public USING (status = 'published');
DROP POLICY IF EXISTS "reviews_admin_write" ON reviews;
CREATE POLICY "reviews_admin_write" ON reviews FOR ALL TO service_role USING (true);

-- tags: 所有人可读，admin 可写
DROP POLICY IF EXISTS "tags_public_read" ON tags;
CREATE POLICY "tags_public_read" ON tags FOR SELECT TO public USING (true);
DROP POLICY IF EXISTS "tags_admin_write" ON tags;
CREATE POLICY "tags_admin_write" ON tags FOR ALL TO service_role USING (true);

-- favorites: 用户只能读写自己的
DROP POLICY IF EXISTS "favorites_own" ON favorites;
CREATE POLICY "favorites_own" ON favorites FOR ALL TO authenticated USING (auth.uid() = user_id);

-- comments: 所有人可读，用户只能操作自己的
DROP POLICY IF EXISTS "comments_public_read" ON comments;
CREATE POLICY "comments_public_read" ON comments FOR SELECT TO public USING (true);
DROP POLICY IF EXISTS "comments_own_write" ON comments;
CREATE POLICY "comments_own_write" ON comments FOR ALL TO authenticated USING (auth.uid() = user_id);

-- follows: 用户只能操作自己的
DROP POLICY IF EXISTS "follows_own" ON follows;
CREATE POLICY "follows_own" ON follows FOR ALL TO authenticated USING (auth.uid() = follower_id);

-- =============================================
-- 示例数据
-- =============================================
INSERT INTO models (name, provider, category, icon, score, description, context_window) VALUES
  ('Claude 3.5 Sonnet', 'Anthropic', '综合', '🧠', 98.5, '最新的 Anthropic 模型，在编程和推理方面表现卓越', 200000),
  ('GPT-4 Turbo', 'OpenAI', '综合', '🤖', 97.2, 'OpenAI 最强大的 GPT-4 版本', 128000),
  ('Gemini 1.5 Pro', 'Google', '综合', '✨', 96.8, 'Google 最强的多模态模型', 1000000),
  ('Llama 3.1 405B', 'Meta', '开源', '🦙', 94.3, '最强大的开源大语言模型', 128000),
  ('Qwen 2.5 72B', '阿里', '开源', '🔮', 93.1, '阿里巴巴通义千问最新版本', 128000),
  ('Mistral Large 2', 'Mistral', '综合', '🌊', 91.7, '欧洲 AI 公司的旗舰模型', 128000),
  ('Deepseek V2.5', '深度求索', '开源', '🔍', 90.4, '中国开源模型，性能优秀', 128000),
  ('Command R+', 'Cohere', 'RAG', '📚', 89.2, '专为 RAG 优化的模型', 128000),
  ('Yi-Large', '零一万物', '综合', 'Yi', 88.5, '李开复创业公司的大模型', 200000),
  ('GLM-4', '智谱', '综合', 'GL', 87.8, '智谱 AI 的最新版本', 128000)
ON CONFLICT DO NOTHING;

INSERT INTO tags (name, slug, color) VALUES
  ('编程', 'programming', '#3B82F6'),
  ('代码生成', 'code-generation', '#8B5CF6'),
  ('创意写作', 'creative-writing', '#EC4899'),
  ('数学推理', 'math', '#F59E0B'),
  ('多模态', 'multimodal', '#10B981'),
  ('RAG', 'rag', '#6366F1'),
  ('开源', 'open-source', '#22C55E'),
  ('中文', 'chinese', '#EF4444'),
  ('对比评测', 'benchmark', '#F97316'),
  ('深度评测', 'deep-review', '#06B6D4')
ON CONFLICT DO NOTHING;

INSERT INTO reviews (model_id, model_name, title, summary, content, reviewer, rating, review_type, tags, is_featured)
SELECT m.id, m.name,
  m.name || ' 深度评测：编程能力质的飞跃',
  '在编程任务中表现出色，支持长上下文，能够快速理解项目结构并提供高质量代码建议',
  '这是一篇关于 ' || m.name || ' 的深度评测文章...',
  'AI评测官',
  4.5,
  '深度评测',
  ARRAY['编程', '代码生成', '深度评测'],
  true
FROM models m WHERE m.name = 'Claude 3.5 Sonnet'
ON CONFLICT DO NOTHING;

INSERT INTO reviews (model_id, model_name, title, summary, content, reviewer, rating, review_type, tags)
SELECT m.id, m.name,
  'GPT-4 Turbo vs ' || m.name || ' 全面对比',
  '对比测试，分析两者在不同场景下的表现差异',
  '这是一篇对比评测文章...',
  '科技前沿',
  4.0,
  '对比测试',
  ARRAY['对比评测', '多模态']
FROM models m WHERE m.name = 'Claude 3.5 Sonnet'
ON CONFLICT DO NOTHING;