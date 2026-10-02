-- 单独保存译文，原始标题、摘要和去重字段保持不变。
ALTER TABLE public.ai_news_items
  ADD COLUMN IF NOT EXISTS title_zh TEXT,
  ADD COLUMN IF NOT EXISTS summary_zh TEXT;
