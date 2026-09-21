-- ═══════════════════════════════════════════════
-- 00003: 线上库 schema 对齐（补齐代码写入所需列）
-- 背景：
--   线上 DB 的 hot_news_raw / repository_metrics 结构与仓库 001 基线不一致
--   （例如 hot_news_raw 缺 is_ai_related），而 001 使用
--   CREATE TABLE IF NOT EXISTS，对已存在表不会补列。
--   本迁移用 ADD COLUMN IF NOT EXISTS 幂等补齐爬虫实际写入的列，
--   可安全重复执行，且不会破坏线上已有数据。
-- 配套：00001（rising_stars 新表）、00002（model_evaluations + models 新列 + 两榜新表）
-- ═══════════════════════════════════════════════

-- ── 1. hot_news_raw：arxiv 爬虫写入 is_ai_related ──────
ALTER TABLE public.hot_news_raw ADD COLUMN IF NOT EXISTS is_ai_related BOOLEAN DEFAULT FALSE;
ALTER TABLE public.hot_news_raw ADD COLUMN IF NOT EXISTS comment_count INTEGER DEFAULT 0;

-- ── 2. repository_metrics：github_trending 爬虫写入的列 ──
-- 线上该表为空，列结构未知；此处逐一兜底补齐，已存在则跳过。
ALTER TABLE public.repository_metrics ADD COLUMN IF NOT EXISTS repo_name      TEXT;
ALTER TABLE public.repository_metrics ADD COLUMN IF NOT EXISTS repo_url       TEXT;
ALTER TABLE public.repository_metrics ADD COLUMN IF NOT EXISTS stars          INTEGER DEFAULT 0;
ALTER TABLE public.repository_metrics ADD COLUMN IF NOT EXISTS forks          INTEGER DEFAULT 0;
ALTER TABLE public.repository_metrics ADD COLUMN IF NOT EXISTS language       TEXT;
ALTER TABLE public.repository_metrics ADD COLUMN IF NOT EXISTS description    TEXT;
ALTER TABLE public.repository_metrics ADD COLUMN IF NOT EXISTS author         TEXT;
ALTER TABLE public.repository_metrics ADD COLUMN IF NOT EXISTS is_ai_related  BOOLEAN DEFAULT FALSE;
ALTER TABLE public.repository_metrics ADD COLUMN IF NOT EXISTS primary_topic  TEXT;
-- 使用 TEXT 而非 metric_source 枚举，避免依赖未同步的自定义类型
ALTER TABLE public.repository_metrics ADD COLUMN IF NOT EXISTS source         TEXT DEFAULT 'github';
ALTER TABLE public.repository_metrics ADD COLUMN IF NOT EXISTS fetched_at     TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- 注释：models 的新列（max_output_tokens / latency_ms / throughput_tps /
-- multimodal_inputs / tool_use / fine_tunable / context_window）由 00002 负责，
-- 此处不重复，避免与 00002 冲突。
