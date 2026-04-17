-- DaCong 数据库初始化 Migration
-- 运行方式：supabase migration new 001_initial_schema
-- 执行：supabase db push 或 psql 直接执行

BEGIN;

-- ── 1. 枚举类型 ────────────────────────────────────────────

DO $$ BEGIN
  CREATE TYPE metric_source AS ENUM ('github', 'huggingface', 'hackernews', 'producthunt');
EXCEPTION WHEN duplicate_object THEN NULL;
END$$;

DO $$ BEGIN
  CREATE TYPE metric_type AS ENUM (
    'github_trending',
    'hf_text_generation',
    'hf_text_to_image',
    'hf_image_to_text',
    'hf_text_to_speech',
    'hf_speech_to_text',
    'hf_embedding',
    'hf_feature_extraction',
    'hn_ai_news',
    'ph_ai_product'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END$$;

DO $$ BEGIN
  CREATE TYPE moderation_status AS ENUM ('pending', 'passed', 'flagged');
EXCEPTION WHEN duplicate_object THEN NULL;
END$$;

-- ── 2. profiles ────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username    TEXT UNIQUE NOT NULL,
  avatar_url  TEXT,
  bio         TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles: own row only"
  ON public.profiles FOR ALL
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- ── 3. models ──────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.models (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL,
  vendor          TEXT NOT NULL,           -- OpenAI / Anthropic / Meta / ...
  category        TEXT NOT NULL,            -- LLM / VLM / TTS / Embedding / ...
  description     TEXT,
  website_url     TEXT,
  api_endpoint    TEXT,
  is_open_source  BOOLEAN DEFAULT FALSE,
  tags            TEXT[] DEFAULT '{}',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(vendor, name)
);
ALTER TABLE public.models ENABLE ROW LEVEL SECURITY;

CREATE POLICY "models: public read"
  ON public.models FOR SELECT USING (true);

CREATE POLICY "models: service role write"
  ON public.models FOR ALL USING (true);

-- ── 4. model_raw_metrics ───────────────────────────────────

CREATE TABLE IF NOT EXISTS public.model_raw_metrics (
  id          BIGSERIAL PRIMARY KEY,
  model_id    UUID REFERENCES public.models(id) ON DELETE CASCADE,
  source      metric_source NOT NULL,
  metric_type metric_type NOT NULL,
  value       NUMERIC,
  metadata    JSONB DEFAULT '{}',
  fetched_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.model_raw_metrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "model_raw_metrics: public read"
  ON public.model_raw_metrics FOR SELECT USING (true);

CREATE POLICY "model_raw_metrics: service role write"
  ON public.model_raw_metrics FOR ALL USING (true);

-- 索引
CREATE INDEX IF NOT EXISTS idx_raw_metrics_model_id
  ON public.model_raw_metrics(model_id);
CREATE INDEX IF NOT EXISTS idx_raw_metrics_fetched_at
  ON public.model_raw_metrics(fetched_at);
CREATE INDEX IF NOT EXISTS idx_raw_metrics_source_type
  ON public.model_raw_metrics(source, metric_type);

-- ── 5. repository_metrics ───────────────────────────────────

CREATE TABLE IF NOT EXISTS public.repository_metrics (
  id              BIGSERIAL PRIMARY KEY,
  repo_name       TEXT NOT NULL,
  repo_url        TEXT NOT NULL,
  stars           INTEGER DEFAULT 0,
  forks           INTEGER DEFAULT 0,
  language        TEXT,
  description     TEXT,
  author          TEXT,
  is_ai_related   BOOLEAN DEFAULT FALSE,
  primary_topic   TEXT,
  source          metric_source DEFAULT 'github',
  fetched_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.repository_metrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "repository_metrics: public read"
  ON public.repository_metrics FOR SELECT USING (true);

CREATE POLICY "repository_metrics: service role write"
  ON public.repository_metrics FOR ALL USING (true);

-- 去重索引（按时间排序，dedup 由爬虫应用层处理）
CREATE INDEX IF NOT EXISTS idx_repo_metrics_dedup
  ON public.repository_metrics(repo_name, source, fetched_at DESC);

-- ── 6. model_ranks ─────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.model_ranks (
  id            BIGSERIAL PRIMARY KEY,
  model_id      UUID REFERENCES public.models(id) ON DELETE CASCADE,
  rank_date     DATE NOT NULL DEFAULT CURRENT_DATE,
  rank_overall  INTEGER,
  rank_category INTEGER,
  score         NUMERIC(10, 4),
  github_stars  INTEGER,
  hf_downloads  BIGINT,
  hn_news_count INTEGER,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(model_id, rank_date)
);
ALTER TABLE public.model_ranks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "model_ranks: public read"
  ON public.model_ranks FOR SELECT USING (true);

CREATE INDEX IF NOT EXISTS idx_model_ranks_date
  ON public.model_ranks(rank_date DESC);

-- ── 7. hot_news_raw ────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.hot_news_raw (
  id          BIGSERIAL PRIMARY KEY,
  source      TEXT NOT NULL,        -- HN / PH / RSS
  title       TEXT NOT NULL,
  url         TEXT NOT NULL,
  summary     TEXT,
  author      TEXT,
  score       INTEGER DEFAULT 0,
  comment_count INTEGER DEFAULT 0,
  is_ai_related BOOLEAN DEFAULT FALSE,
  fetched_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.hot_news_raw ENABLE ROW LEVEL SECURITY;

CREATE POLICY "hot_news_raw: public read"
  ON public.hot_news_raw FOR SELECT USING (true);

CREATE POLICY "hot_news_raw: service role write"
  ON public.hot_news_raw FOR ALL USING (true);

CREATE INDEX IF NOT EXISTS idx_hot_news_fetched
  ON public.hot_news_raw(fetched_at DESC);
CREATE INDEX IF NOT EXISTS idx_hot_news_source
  ON public.hot_news_raw(source, fetched_at DESC);

-- ── 8. trending_keywords ────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.trending_keywords (
  id          BIGSERIAL PRIMARY KEY,
  keyword     TEXT NOT NULL UNIQUE,
  heat_score  INTEGER DEFAULT 0,
  rank        INTEGER,
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.trending_keywords ENABLE ROW LEVEL SECURITY;

CREATE POLICY "trending_keywords: public read"
  ON public.trending_keywords FOR SELECT USING (true);

-- ── 9. topics ───────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.topics (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT UNIQUE NOT NULL,
  slug        TEXT UNIQUE NOT NULL,
  description TEXT,
  post_count  INTEGER DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.topics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "topics: public read"
  ON public.topics FOR SELECT USING (true);

INSERT INTO public.topics (name, slug, description) VALUES
  ('LLM', 'llm', '大语言模型'),
  ('文生图', 'text-to-image', 'Text-to-Image 生成模型'),
  ('语音', 'audio', '语音识别与合成'),
  ('Embedding', 'embedding', '向量嵌入模型'),
  ('视频生成', 'video', '视频生成模型')
ON CONFLICT DO NOTHING;

-- ── 10. posts ──────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.posts (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title               TEXT NOT NULL,
  content             TEXT NOT NULL DEFAULT '',
  post_type           TEXT DEFAULT 'text',  -- text / link / image
  media_urls          TEXT[] DEFAULT '{}',
  topic_id            UUID REFERENCES public.topics(id),
  like_count          INTEGER DEFAULT 0,
  comment_count       INTEGER DEFAULT 0,
  share_count         INTEGER DEFAULT 0,
  moderation_status   moderation_status DEFAULT 'pending',
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "posts: public read passed"
  ON public.posts FOR SELECT USING (
    moderation_status = 'passed' OR auth.uid() = user_id
  );
CREATE POLICY "posts: authenticated insert"
  ON public.posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "posts: own update"
  ON public.posts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "posts: own delete"
  ON public.posts FOR DELETE USING (auth.uid() = user_id);

-- ── 11. comments ────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.comments (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id     UUID REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  parent_id   UUID REFERENCES public.comments(id) ON DELETE CASCADE,
  content     TEXT NOT NULL,
  like_count  INTEGER DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "comments: public read"
  ON public.comments FOR SELECT USING (true);
CREATE POLICY "comments: authenticated insert"
  ON public.comments FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ── 12. likes ──────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.likes (
  id          BIGSERIAL PRIMARY KEY,
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  target_type TEXT NOT NULL,   -- post / comment
  target_id   UUID NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, target_type, target_id)
);
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "likes: own read"
  ON public.likes FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "likes: authenticated insert"
  ON public.likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "likes: own delete"
  ON public.likes FOR DELETE USING (auth.uid() = user_id);

-- ── 13. follows ────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.follows (
  id           BIGSERIAL PRIMARY KEY,
  follower_id  UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  following_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(follower_id, following_id)
);
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;

CREATE POLICY "follows: public read"
  ON public.follows FOR SELECT USING (true);
CREATE POLICY "follows: authenticated insert"
  ON public.follows FOR INSERT WITH CHECK (auth.uid() = follower_id);
CREATE POLICY "follows: own delete"
  ON public.follows FOR DELETE USING (auth.uid() = follower_id);

-- ── 14. 自动更新 updated_at 触发器 ──────────────────────────

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER models_updated_at
  BEFORE UPDATE ON public.models
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER posts_updated_at
  BEFORE UPDATE ON public.posts
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ── 15. 更新评论数触发器 ───────────────────────────────────

CREATE OR REPLACE FUNCTION public.update_post_comment_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.posts SET comment_count = comment_count + 1 WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.posts SET comment_count = comment_count - 1 WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER comment_count_trigger
  AFTER INSERT OR DELETE ON public.comments
  FOR EACH ROW EXECUTE FUNCTION public.update_post_comment_count();

-- ── 16. 更新点赞数触发器 ───────────────────────────────────

CREATE OR REPLACE FUNCTION public.update_like_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.posts SET like_count = like_count + 1
      WHERE id = NEW.target_id AND NEW.target_type = 'post';
    UPDATE public.comments SET like_count = like_count + 1
      WHERE id = NEW.target_id AND NEW.target_type = 'comment';
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.posts SET like_count = like_count - 1
      WHERE id = OLD.target_id AND OLD.target_type = 'post';
    UPDATE public.comments SET like_count = like_count - 1
      WHERE id = OLD.target_id AND OLD.target_type = 'comment';
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER like_count_trigger
  AFTER INSERT OR DELETE ON public.likes
  FOR EACH ROW EXECUTE FUNCTION public.update_like_count();

-- ── 17. 更新话题帖子数触发器 ────────────────────────────────

CREATE OR REPLACE FUNCTION public.update_topic_post_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.topic_id IS NOT NULL THEN
    UPDATE public.topics SET post_count = post_count + 1 WHERE id = NEW.topic_id;
  ELSIF TG_OP = 'DELETE' AND OLD.topic_id IS NOT NULL THEN
    UPDATE public.topics SET post_count = post_count - 1 WHERE id = OLD.topic_id;
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.topic_id IS DISTINCT FROM NEW.topic_id THEN
      IF OLD.topic_id IS NOT NULL THEN
        UPDATE public.topics SET post_count = post_count - 1 WHERE id = OLD.topic_id;
      END IF;
      IF NEW.topic_id IS NOT NULL THEN
        UPDATE public.topics SET post_count = post_count + 1 WHERE id = NEW.topic_id;
      END IF;
    END IF;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER topic_post_count_trigger
  AFTER INSERT OR DELETE OR UPDATE OF topic_id ON public.posts
  FOR EACH ROW EXECUTE FUNCTION public.update_topic_post_count();

-- ── 18. 统计粉丝数视图 ─────────────────────────────────────

CREATE OR REPLACE VIEW public.profile_stats AS
SELECT
  p.id,
  p.username,
  p.avatar_url,
  p.bio,
  p.created_at,
  p.updated_at,
  COUNT(DISTINCT CASE WHEN f.follower_id   = p.id THEN f.id END) AS following_count,
  COUNT(DISTINCT CASE WHEN f2.following_id = p.id THEN f2.id END) AS follower_count
FROM public.profiles p
LEFT JOIN public.follows f   ON f.follower_id   = p.id
LEFT JOIN public.follows f2 ON f2.following_id = p.id
LEFT JOIN public.posts       ON posts.user_id    = p.id
GROUP BY p.id;

COMMIT;
