-- 生产发布顺序（历史库缺少迁移记录，避免直接运行全部遗留迁移）：
-- 1. migrations/20260808_00003_schema_reconcile.sql
-- 2. 本文件下方的 vendor 补列
-- 3. migrations/20260807_00001_rising_stars.sql
-- 4. migrations/20260807_00002_model_evaluations.sql
-- 5. migrations/20260922_00004_ai_news_pipeline.sql
-- 6. migrations/20261002_00005_ai_news_bootstrap_access.sql
-- 所有步骤在同一个事务中应用，并登记迁移历史。

ALTER TABLE public.models ADD COLUMN IF NOT EXISTS vendor TEXT;
UPDATE public.models SET vendor = provider WHERE vendor IS NULL;
