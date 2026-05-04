-- =============================================
-- 爬虫数据表 - DaCong Spider
-- 为 dacong-spider 添加爬虫原始数据存储表
-- =============================================

-- 热点新闻原始数据表
CREATE TABLE IF NOT EXISTS hot_news_raw (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source TEXT NOT NULL,                    -- "HN", "PH" 等
  title TEXT NOT NULL,
  url TEXT NOT NULL,
  summary TEXT DEFAULT '',
  author TEXT DEFAULT '',
  score INTEGER DEFAULT 0,
  fetched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT hot_news_unique_url UNIQUE (url)
);

-- 模型原始指标表
CREATE TABLE IF NOT EXISTS model_raw_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  model_id TEXT NOT NULL,
  source TEXT NOT NULL,                     -- "github", "huggingface", "openrouter"
  metric_type TEXT NOT NULL,
  metric_value JSONB NOT NULL,
  fetched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- GitHub 仓库指标表
CREATE TABLE IF NOT EXISTS repository_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name TEXT NOT NULL UNIQUE,          -- "owner/repo"
  description TEXT,
  language TEXT,
  stars_today INTEGER DEFAULT 0,
  total_stars INTEGER DEFAULT 0,
  forks INTEGER DEFAULT 0,
  url TEXT NOT NULL,
  fetched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 热搜词表
CREATE TABLE IF NOT EXISTS trending_keywords (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  keyword TEXT NOT NULL UNIQUE,
  count INTEGER DEFAULT 1,
  source TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 索引
-- =============================================
CREATE INDEX IF NOT EXISTS idx_hot_news_source ON hot_news_raw(source);
CREATE INDEX IF NOT EXISTS idx_hot_news_score ON hot_news_raw(score DESC);
CREATE INDEX IF NOT EXISTS idx_hot_news_fetched_at ON hot_news_raw(fetched_at DESC);
CREATE INDEX IF NOT EXISTS idx_hot_news_created_at ON hot_news_raw(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_model_metrics_model_id ON model_raw_metrics(model_id);
CREATE INDEX IF NOT EXISTS idx_model_metrics_source ON model_raw_metrics(source);
CREATE INDEX IF NOT EXISTS idx_model_metrics_fetched_at ON model_raw_metrics(fetched_at DESC);

CREATE INDEX IF NOT EXISTS idx_repo_metrics_stars ON repository_metrics(total_stars DESC);
CREATE INDEX IF NOT EXISTS idx_repo_metrics_fetched_at ON repository_metrics(fetched_at DESC);

-- =============================================
-- RLS 策略
-- =============================================
ALTER TABLE hot_news_raw ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "hot_news_public_read" ON hot_news_raw;
CREATE POLICY "hot_news_public_read" ON hot_news_raw
  FOR SELECT TO public USING (true);
DROP POLICY IF EXISTS "hot_news_service_write" ON hot_news_raw;
CREATE POLICY "hot_news_service_write" ON hot_news_raw
  FOR ALL TO service_role USING (true);

ALTER TABLE model_raw_metrics ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "model_metrics_public_read" ON model_raw_metrics;
CREATE POLICY "model_metrics_public_read" ON model_raw_metrics
  FOR SELECT TO public USING (true);
DROP POLICY IF EXISTS "model_metrics_service_write" ON model_raw_metrics;
CREATE POLICY "model_metrics_service_write" ON model_raw_metrics
  FOR ALL TO service_role USING (true);

ALTER TABLE repository_metrics ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "repo_metrics_public_read" ON repository_metrics;
CREATE POLICY "repo_metrics_public_read" ON repository_metrics
  FOR SELECT TO public USING (true);
DROP POLICY IF EXISTS "repo_metrics_service_write" ON repository_metrics;
CREATE POLICY "repo_metrics_service_write" ON repository_metrics
  FOR ALL TO service_role USING (true);

ALTER TABLE trending_keywords ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "trending_keywords_public_read" ON trending_keywords;
CREATE POLICY "trending_keywords_public_read" ON trending_keywords
  FOR SELECT TO public USING (true);
DROP POLICY IF EXISTS "trending_keywords_service_write" ON trending_keywords;
CREATE POLICY "trending_keywords_service_write" ON trending_keywords
  FOR ALL TO service_role USING (true);
