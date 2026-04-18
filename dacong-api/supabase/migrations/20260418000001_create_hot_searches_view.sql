-- Migration: Create hot searches view and function
-- Description: 统计热门搜索词，用于搜索页面展示

-- 创建热门搜索视图
CREATE OR REPLACE VIEW hot_searches AS
SELECT
  event_data->>'query' as search_query,
  COUNT(*) as search_count,
  MAX(created_at) as last_searched_at
FROM analytics_events
WHERE
  event_type = 'search'
  AND created_at > NOW() - INTERVAL '7 days'
  AND event_data->>'query' IS NOT NULL
  AND LENGTH(event_data->>'query') > 0
GROUP BY event_data->>'query'
ORDER BY search_count DESC
LIMIT 20;

-- 创建获取热门搜索的函数
CREATE OR REPLACE FUNCTION get_hot_searches(result_limit INT DEFAULT 10)
RETURNS TABLE (
  search_query TEXT,
  search_count BIGINT,
  last_searched_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    hs.search_query,
    hs.search_count,
    hs.last_searched_at
  FROM hot_searches hs
  LIMIT result_limit;
END;
$$;

-- 注释
COMMENT ON VIEW hot_searches IS '热门搜索统计视图（最近7天）';
COMMENT ON FUNCTION get_hot_searches IS '获取热门搜索词列表';
