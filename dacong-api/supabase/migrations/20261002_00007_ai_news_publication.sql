-- 原始发布日期与采集时间分开保存，旧数据日期未知时保持 NULL。
ALTER TABLE public.hot_news_raw
  ADD COLUMN IF NOT EXISTS source_published_at TIMESTAMPTZ;
