-- AI 动态精选层、来源配置与每日摘要。
-- hot_news_raw 保持为原始采集层，公开页面只读取本迁移创建的精选表。

CREATE TABLE IF NOT EXISTS public.ai_source_settings (
  source TEXT PRIMARY KEY,
  tier TEXT NOT NULL CHECK (tier IN ('official', 'professional', 'community')),
  default_category TEXT CHECK (default_category IN ('model', 'developer_tool', 'open_source', 'research', 'industry')),
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.ai_news_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_key TEXT NOT NULL UNIQUE,
  normalized_title TEXT NOT NULL,
  title TEXT NOT NULL,
  summary TEXT NOT NULL DEFAULT '',
  language TEXT NOT NULL DEFAULT 'en' CHECK (language IN ('zh', 'en', 'other')),
  category TEXT NOT NULL CHECK (category IN ('model', 'developer_tool', 'open_source', 'research', 'industry')),
  source_tier TEXT NOT NULL CHECK (source_tier IN ('official', 'professional', 'community')),
  quality_score INTEGER NOT NULL CHECK (quality_score BETWEEN 0 AND 100),
  importance_score INTEGER NOT NULL DEFAULT 0 CHECK (importance_score BETWEEN 0 AND 100),
  status TEXT NOT NULL DEFAULT 'quarantined' CHECK (status IN ('published', 'quarantined', 'withdrawn')),
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 线上旧表使用 UUID，仓库基线使用 BIGINT；沿用原始层的主键类型。
DO $$
DECLARE raw_id_type TEXT;
BEGIN
  SELECT format_type(atttypid, atttypmod) INTO raw_id_type
  FROM pg_attribute
  WHERE attrelid = 'public.hot_news_raw'::regclass AND attname = 'id';
  EXECUTE format($ddl$
CREATE TABLE IF NOT EXISTS public.ai_news_sources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  news_item_id UUID NOT NULL REFERENCES public.ai_news_items(id) ON DELETE CASCADE,
  raw_news_id %s NOT NULL REFERENCES public.hot_news_raw(id) ON DELETE CASCADE,
  source TEXT NOT NULL,
  url TEXT NOT NULL,
  original_title TEXT NOT NULL,
  source_published_at TIMESTAMPTZ,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(raw_news_id),
  UNIQUE(news_item_id, url)
);
$ddl$, raw_id_type);
END;
$$;

CREATE TABLE IF NOT EXISTS public.daily_digests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  digest_date DATE NOT NULL UNIQUE,
  title TEXT NOT NULL,
  intro TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'published' CHECK (status IN ('published', 'withdrawn')),
  item_count INTEGER NOT NULL DEFAULT 0,
  published_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.daily_digest_items (
  digest_id UUID NOT NULL REFERENCES public.daily_digests(id) ON DELETE CASCADE,
  news_item_id UUID NOT NULL REFERENCES public.ai_news_items(id) ON DELETE CASCADE,
  rank INTEGER NOT NULL CHECK (rank > 0),
  category TEXT NOT NULL,
  PRIMARY KEY (digest_id, news_item_id),
  UNIQUE(digest_id, rank)
);

CREATE INDEX IF NOT EXISTS idx_ai_news_feed
  ON public.ai_news_items(status, published_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_news_category
  ON public.ai_news_items(category, published_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_news_sources_item
  ON public.ai_news_sources(news_item_id);
CREATE INDEX IF NOT EXISTS idx_daily_digests_date
  ON public.daily_digests(digest_date DESC);

INSERT INTO public.ai_source_settings(source, tier, default_category)
VALUES
  ('OpenAI', 'official', 'model'),
  ('Anthropic', 'official', 'model'),
  ('Google_AI', 'official', 'model'),
  ('TheSequence', 'professional', 'industry'),
  ('HuggingFace', 'official', 'open_source'),
  ('GitHub', 'official', 'open_source'),
  ('arxiv', 'professional', 'research'),
  ('VentureBeat_AI', 'professional', 'industry'),
  ('MIT_Tech_AI', 'professional', 'industry'),
  ('HN', 'community', 'developer_tool'),
  ('Reddit', 'community', 'industry'),
  ('X', 'community', 'industry'),
  ('Bluesky', 'community', 'industry')
ON CONFLICT (source) DO NOTHING;

ALTER TABLE public.ai_source_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_news_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_news_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_digests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_digest_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "ai source settings: public read enabled" ON public.ai_source_settings;
CREATE POLICY "ai source settings: public read enabled" ON public.ai_source_settings
  FOR SELECT USING (enabled = TRUE);
DROP POLICY IF EXISTS "ai source settings: service write" ON public.ai_source_settings;
CREATE POLICY "ai source settings: service write" ON public.ai_source_settings
  FOR ALL TO service_role USING (TRUE) WITH CHECK (TRUE);

DROP POLICY IF EXISTS "ai news: public read published" ON public.ai_news_items;
CREATE POLICY "ai news: public read published" ON public.ai_news_items
  FOR SELECT USING (status = 'published');
DROP POLICY IF EXISTS "ai news: service write" ON public.ai_news_items;
CREATE POLICY "ai news: service write" ON public.ai_news_items
  FOR ALL TO service_role USING (TRUE) WITH CHECK (TRUE);

DROP POLICY IF EXISTS "ai news sources: public read published" ON public.ai_news_sources;
CREATE POLICY "ai news sources: public read published" ON public.ai_news_sources
  FOR SELECT USING (EXISTS (
    SELECT 1 FROM public.ai_news_items n
    WHERE n.id = news_item_id AND n.status = 'published'
  ));
DROP POLICY IF EXISTS "ai news sources: service write" ON public.ai_news_sources;
CREATE POLICY "ai news sources: service write" ON public.ai_news_sources
  FOR ALL TO service_role USING (TRUE) WITH CHECK (TRUE);

DROP POLICY IF EXISTS "daily digests: public read published" ON public.daily_digests;
CREATE POLICY "daily digests: public read published" ON public.daily_digests
  FOR SELECT USING (status = 'published');
DROP POLICY IF EXISTS "daily digests: service write" ON public.daily_digests;
CREATE POLICY "daily digests: service write" ON public.daily_digests
  FOR ALL TO service_role USING (TRUE) WITH CHECK (TRUE);

DROP POLICY IF EXISTS "daily digest items: public read published" ON public.daily_digest_items;
CREATE POLICY "daily digest items: public read published" ON public.daily_digest_items
  FOR SELECT USING (EXISTS (
    SELECT 1 FROM public.daily_digests d
    WHERE d.id = digest_id AND d.status = 'published'
  ));
DROP POLICY IF EXISTS "daily digest items: service write" ON public.daily_digest_items;
CREATE POLICY "daily digest items: service write" ON public.daily_digest_items
  FOR ALL TO service_role USING (TRUE) WITH CHECK (TRUE);
