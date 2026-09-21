-- ═══════════════════════════════════════════════════════════
-- M1: GitHub 快速涨星（rising stars）
-- 依赖：001_initial_schema.sql 的 public.repository_metrics
-- ═══════════════════════════════════════════════════════════

-- ── 1. 飙升榜快照表（compute-rising-stars 每日计算后写入）──

CREATE TABLE IF NOT EXISTS public.rising_stars_rankings (
  id            BIGSERIAL PRIMARY KEY,
  repo_name     TEXT NOT NULL,
  repo_url      TEXT NOT NULL,
  owner         TEXT,
  language      TEXT,
  description   TEXT,
  total_stars   INTEGER DEFAULT 0,
  stars_1d      INTEGER DEFAULT 0,   -- 近 1 日新增
  stars_7d      INTEGER DEFAULT 0,   -- 近 7 日新增
  stars_30d     INTEGER DEFAULT 0,   -- 近 30 日新增
  velocity      NUMERIC(10, 4),      -- 增速斜率（stars/day，最小二乘拟合）
  rank_score    NUMERIC(10, 4),      -- 综合排序分
  snapshot_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (repo_name, snapshot_date)
);

ALTER TABLE public.rising_stars_rankings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rising_stars_rankings: public read"
  ON public.rising_stars_rankings FOR SELECT USING (true);

CREATE POLICY "rising_stars_rankings: service role write"
  ON public.rising_stars_rankings FOR ALL USING (true);

-- 榜单查询：按快照日 + 综合分倒序
CREATE INDEX IF NOT EXISTS idx_rising_stars_snapshot_score
  ON public.rising_stars_rankings(snapshot_date DESC, rank_score DESC);

-- 语言过滤
CREATE INDEX IF NOT EXISTS idx_rising_stars_language
  ON public.rising_stars_rankings(snapshot_date DESC, language);

-- ── 2. star 时间序列视图（基于 repository_metrics，无需额外存储）──

CREATE OR REPLACE VIEW public.v_repo_star_history AS
SELECT
  repo_name,
  repo_url,
  language,
  description,
  stars AS total_stars,
  fetched_at,
  stars - LAG(stars) OVER (
    PARTITION BY repo_name ORDER BY fetched_at
  ) AS daily_delta
FROM public.repository_metrics
ORDER BY repo_name, fetched_at;

-- ── 3. 计算层扫描索引 ────────────────────────────────────
-- compute-rising-stars 按 fetched_at >= now() - 30d 全表扫描，
-- 已有的 idx_repo_metrics_dedup(repo_name, source, fetched_at DESC)
-- 无法支撑纯时间范围过滤，补一个时间维索引。
CREATE INDEX IF NOT EXISTS idx_repo_metrics_fetched_at
  ON public.repository_metrics(fetched_at DESC);
