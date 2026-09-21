-- ═══════════════════════════════════════════════════════════
-- M2: 大模型评测聚合 + M3: 大模型能力字段
-- 依赖：001_initial_schema.sql 的 public.models
-- ═══════════════════════════════════════════════════════════

-- ── 1. 统一评测表 ─────────────────────────────────────────
-- 所有来源（artificial_analysis / lmarena / swebench）的 benchmark
-- 分数都落到这里，按 (模型, benchmark, 分类, 来源, 评测日) 每日一条。

CREATE TABLE IF NOT EXISTS public.model_evaluations (
  id          BIGSERIAL PRIMARY KEY,
  model_id    UUID REFERENCES public.models(id) ON DELETE CASCADE,
  benchmark   TEXT NOT NULL,        -- 'MMLU-Pro' | 'GPQA' | 'HumanEval' | 'MATH-500' | 'Arena-ELO'
  score       NUMERIC(10, 4),
  category    TEXT,                 -- 'general' | 'coding' | 'math' | 'vision' | 'chinese' | 'agentic'
  source      TEXT NOT NULL,        -- 'artificial_analysis' | 'lmarena'
  eval_date   DATE NOT NULL DEFAULT CURRENT_DATE,
  raw_data    JSONB DEFAULT '{}',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (model_id, benchmark, category, source, eval_date)
);

ALTER TABLE public.model_evaluations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "model_evaluations: public read"
  ON public.model_evaluations FOR SELECT USING (true);

CREATE POLICY "model_evaluations: service role write"
  ON public.model_evaluations FOR ALL USING (true);

-- 模型详情页：取某模型最新一批评测
CREATE INDEX IF NOT EXISTS idx_model_evaluations_model
  ON public.model_evaluations(model_id, eval_date DESC);

-- 单 benchmark 横向对比（get-model-evaluations 的 benchmark 过滤）
CREATE INDEX IF NOT EXISTS idx_model_evaluations_benchmark
  ON public.model_evaluations(benchmark, eval_date DESC);

-- 分类维度筛选
CREATE INDEX IF NOT EXISTS idx_model_evaluations_category
  ON public.model_evaluations(category, eval_date DESC);

-- ── 2. models 能力字段扩展（M3）────────────────────────────

ALTER TABLE public.models ADD COLUMN IF NOT EXISTS max_output_tokens INTEGER;
ALTER TABLE public.models ADD COLUMN IF NOT EXISTS latency_ms        INTEGER;
ALTER TABLE public.models ADD COLUMN IF NOT EXISTS throughput_tps    INTEGER;
ALTER TABLE public.models ADD COLUMN IF NOT EXISTS multimodal_inputs TEXT[];
ALTER TABLE public.models ADD COLUMN IF NOT EXISTS tool_use          BOOLEAN DEFAULT FALSE;
ALTER TABLE public.models ADD COLUMN IF NOT EXISTS fine_tunable      BOOLEAN DEFAULT FALSE;
ALTER TABLE public.models ADD COLUMN IF NOT EXISTS context_window    INTEGER;

COMMENT ON COLUMN public.models.latency_ms IS '首 token 延迟中位数（毫秒）';
COMMENT ON COLUMN public.models.throughput_tps IS '输出速度中位数（tokens/s）';
COMMENT ON COLUMN public.models.multimodal_inputs IS '支持的输入模态，如 {text,image,speech,video}';

-- ── 3. 补建爬虫直接写入但此前缺失迁移的排行榜表 ────────────
-- dacong-spider/spiders/{arena,artificial_analysis}.py 一直直接 upsert
-- 这两张表，字段以爬虫实际写入的键为准。

-- 3.1 LMArena（spiders/arena.py，经 BaseRankingsSpider.save_to_table 批量 upsert）
CREATE TABLE IF NOT EXISTS public.arena_rankings (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  model_name          TEXT NOT NULL,
  elo_score           NUMERIC(10, 4),
  confidence_interval TEXT,
  vote_count          INTEGER,
  category            TEXT DEFAULT 'general',
  company             TEXT,
  -- 爬虫不写此列，靠默认值实现「同模型同分类每天一条」
  snapshot_date       DATE NOT NULL DEFAULT CURRENT_DATE,
  fetched_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (model_name, category, snapshot_date)
);

ALTER TABLE public.arena_rankings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "arena_rankings: public read"
  ON public.arena_rankings FOR SELECT USING (true);

CREATE POLICY "arena_rankings: service role write"
  ON public.arena_rankings FOR ALL USING (true);

CREATE INDEX IF NOT EXISTS idx_arena_rankings_elo
  ON public.arena_rankings(snapshot_date DESC, elo_score DESC);

CREATE INDEX IF NOT EXISTS idx_arena_rankings_model
  ON public.arena_rankings(model_name);

-- 3.2 Artificial Analysis（spiders/artificial_analysis.py，upsert on_conflict=slug）
CREATE TABLE IF NOT EXISTS public.artificial_analysis_rankings (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  model_name                TEXT NOT NULL,
  slug                      TEXT NOT NULL UNIQUE,   -- 爬虫的 on_conflict 目标
  provider                  TEXT,
  provider_id               TEXT,
  provider_string           TEXT,
  price_1m_input_tokens     NUMERIC(12, 6),
  price_1m_output_tokens    NUMERIC(12, 6),
  price_1m_blended_0_3_1    NUMERIC(12, 6),
  price_1m_blended_7_2_1    NUMERIC(12, 6),
  price_1m_blended_0_1_1    NUMERIC(12, 6),
  price_1m_blended_100_1_1  NUMERIC(12, 6),
  context_window_tokens     INTEGER,
  context_window_formatted  TEXT,
  short_name                TEXT,
  model_label               TEXT,
  logo_url                  TEXT,
  logo_small_url            TEXT,
  host_color                TEXT,
  json_mode                 BOOLEAN DEFAULT FALSE,
  function_calling          BOOLEAN DEFAULT FALSE,
  supports_images           BOOLEAN DEFAULT FALSE,
  cache_hit_price           NUMERIC(12, 6),
  cache_write_price         NUMERIC(12, 6),
  image_input_pricing_notes TEXT,
  fetched_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.artificial_analysis_rankings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "artificial_analysis_rankings: public read"
  ON public.artificial_analysis_rankings FOR SELECT USING (true);

CREATE POLICY "artificial_analysis_rankings: service role write"
  ON public.artificial_analysis_rankings FOR ALL USING (true);

CREATE INDEX IF NOT EXISTS idx_aa_rankings_model
  ON public.artificial_analysis_rankings(model_name);

CREATE INDEX IF NOT EXISTS idx_aa_rankings_provider
  ON public.artificial_analysis_rankings(provider);
