-- Migration: Create views
-- Description: 创建统计和查询视图

-- 1. 内容统计视图
CREATE OR REPLACE VIEW content_stats AS
SELECT
  pc.id,
  pc.content_type,
  pc.title_zh,
  pc.scenario,
  pc.view_count,
  pc.helpful_count,
  pc.unhelpful_count,
  pc.share_count,
  -- 计算有用率
  CASE
    WHEN (pc.helpful_count + pc.unhelpful_count) > 0
    THEN ROUND(pc.helpful_count::NUMERIC / (pc.helpful_count + pc.unhelpful_count), 2)
    ELSE NULL
  END AS helpful_rate,
  pc.published_at,
  pc.updated_at
FROM published_content pc
ORDER BY pc.published_at DESC;

COMMENT ON VIEW content_stats IS '内容统计视图';

-- 2. 待审核队列视图
CREATE OR REPLACE VIEW review_queue AS
SELECT
  gc.id,
  gc.content_type,
  gc.title_zh,
  gc.scenario,
  gc.ai_confidence,
  gc.quality_score,
  gc.review_status,
  gc.generated_at,
  -- 计算优先级分数（低置信度优先）
  CASE
    WHEN gc.ai_confidence < 0.85 THEN 10
    WHEN gc.quality_score < 0.8 THEN 8
    ELSE 0
  END AS priority_score,
  gc.created_at
FROM generated_content gc
WHERE gc.review_status = 'pending'
ORDER BY priority_score DESC, gc.generated_at ASC;

COMMENT ON VIEW review_queue IS '待审核队列视图（按优先级排序）';

-- 3. 爬虫统计视图
CREATE OR REPLACE VIEW spider_stats AS
SELECT
  spider_name,
  source,
  COUNT(*) AS total_runs,
  SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END) AS success_count,
  SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) AS failed_count,
  SUM(items_scraped) AS total_items_scraped,
  SUM(items_saved) AS total_items_saved,
  AVG(duration_seconds) AS avg_duration_seconds,
  MAX(started_at) AS last_run_at
FROM spider_logs
GROUP BY spider_name, source
ORDER BY last_run_at DESC;

COMMENT ON VIEW spider_stats IS '爬虫统计视图';
