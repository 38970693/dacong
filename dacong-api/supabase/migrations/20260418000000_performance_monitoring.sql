-- 性能监控相关表和函数

-- 1. 性能指标表
CREATE TABLE IF NOT EXISTS performance_metrics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service VARCHAR(50) NOT NULL,
  metric_type VARCHAR(50) NOT NULL,
  metric_name VARCHAR(100) NOT NULL,
  metric_value FLOAT NOT NULL,
  tags JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_performance_metrics_service ON performance_metrics(service);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_created_at ON performance_metrics(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_type ON performance_metrics(metric_type);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_metric_name ON performance_metrics(metric_name);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_tags ON performance_metrics USING GIN(tags);

-- 2. 慢查询日志表
CREATE TABLE IF NOT EXISTS slow_queries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  query_text TEXT NOT NULL,
  duration_ms INT NOT NULL,
  parameters JSONB,
  user_id UUID,
  called_at TIMESTAMPTZ DEFAULT NOW()
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_slow_queries_duration ON slow_queries(duration_ms DESC);
CREATE INDEX IF NOT EXISTS idx_slow_queries_called_at ON slow_queries(called_at DESC);

-- 3. 启用慢查询日志（需要超级用户权限，在生产环境由 DBA 执行）
-- ALTER SYSTEM SET log_min_duration_statement = 1000; -- 1秒
-- SELECT pg_reload_conf();

-- 4. 创建性能统计函数
CREATE OR REPLACE FUNCTION get_performance_stats(time_range TEXT DEFAULT '1h')
RETURNS TABLE (
  endpoint TEXT,
  method TEXT,
  avg_duration FLOAT,
  p50_duration FLOAT,
  p95_duration FLOAT,
  p99_duration FLOAT,
  request_count BIGINT,
  error_count BIGINT,
  error_rate FLOAT
) AS $$
DECLARE
  interval_value INTERVAL;
BEGIN
  -- 解析时间范围
  interval_value := CASE
    WHEN time_range = '5m' THEN INTERVAL '5 minutes'
    WHEN time_range = '15m' THEN INTERVAL '15 minutes'
    WHEN time_range = '1h' THEN INTERVAL '1 hour'
    WHEN time_range = '6h' THEN INTERVAL '6 hours'
    WHEN time_range = '24h' THEN INTERVAL '24 hours'
    WHEN time_range = '7d' THEN INTERVAL '7 days'
    ELSE INTERVAL '1 hour'
  END;

  RETURN QUERY
  SELECT
    tags->>'endpoint' AS endpoint,
    tags->>'method' AS method,
    AVG(metric_value) AS avg_duration,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY metric_value) AS p50_duration,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY metric_value) AS p95_duration,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY metric_value) AS p99_duration,
    COUNT(*) AS request_count,
    COUNT(*) FILTER (WHERE (tags->>'error')::boolean = true) AS error_count,
    (COUNT(*) FILTER (WHERE (tags->>'error')::boolean = true)::FLOAT / NULLIF(COUNT(*), 0) * 100) AS error_rate
  FROM performance_metrics
  WHERE
    service = 'api'
    AND metric_type = 'api_call'
    AND created_at >= NOW() - interval_value
  GROUP BY tags->>'endpoint', tags->>'method'
  ORDER BY avg_duration DESC;
END;
$$ LANGUAGE plpgsql;

-- 5. 创建慢查询统计函数
CREATE OR REPLACE FUNCTION get_slow_queries_stats(time_range TEXT DEFAULT '1h')
RETURNS TABLE (
  query_pattern TEXT,
  avg_duration_ms FLOAT,
  max_duration_ms INT,
  call_count BIGINT,
  total_time_ms BIGINT
) AS $$
DECLARE
  interval_value INTERVAL;
BEGIN
  interval_value := CASE
    WHEN time_range = '5m' THEN INTERVAL '5 minutes'
    WHEN time_range = '15m' THEN INTERVAL '15 minutes'
    WHEN time_range = '1h' THEN INTERVAL '1 hour'
    WHEN time_range = '6h' THEN INTERVAL '6 hours'
    WHEN time_range = '24h' THEN INTERVAL '24 hours'
    WHEN time_range = '7d' THEN INTERVAL '7 days'
    ELSE INTERVAL '1 hour'
  END;

  RETURN QUERY
  SELECT
    -- 简化查询文本，移除具体参数
    REGEXP_REPLACE(query_text, '\$\d+', '$N', 'g') AS query_pattern,
    AVG(duration_ms) AS avg_duration_ms,
    MAX(duration_ms) AS max_duration_ms,
    COUNT(*) AS call_count,
    SUM(duration_ms) AS total_time_ms
  FROM slow_queries
  WHERE called_at >= NOW() - interval_value
  GROUP BY query_pattern
  ORDER BY total_time_ms DESC
  LIMIT 50;
END;
$$ LANGUAGE plpgsql;

-- 6. 创建性能告警触发器
CREATE OR REPLACE FUNCTION check_performance_threshold()
RETURNS TRIGGER AS $$
BEGIN
  -- 如果响应时间超过 3 秒，记录告警
  IF NEW.metric_type = 'api_call' AND NEW.metric_value > 3000 THEN
    INSERT INTO alerts (
      alert_type,
      severity,
      title,
      message,
      metadata
    ) VALUES (
      'performance',
      'critical',
      'Slow API Response Detected',
      format('Endpoint %s took %s ms to respond', NEW.tags->>'endpoint', NEW.metric_value),
      jsonb_build_object(
        'endpoint', NEW.tags->>'endpoint',
        'method', NEW.tags->>'method',
        'duration', NEW.metric_value,
        'metric_id', NEW.id
      )
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_performance_threshold
AFTER INSERT ON performance_metrics
FOR EACH ROW
EXECUTE FUNCTION check_performance_threshold();

-- 7. 创建数据清理任务（保留 30 天数据）
CREATE OR REPLACE FUNCTION cleanup_old_performance_metrics()
RETURNS void AS $$
BEGIN
  DELETE FROM performance_metrics
  WHERE created_at < NOW() - INTERVAL '30 days';

  DELETE FROM slow_queries
  WHERE called_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- 8. 创建性能报告视图
CREATE OR REPLACE VIEW performance_summary AS
SELECT
  DATE_TRUNC('hour', created_at) AS hour,
  service,
  metric_type,
  metric_name,
  AVG(metric_value) AS avg_value,
  MIN(metric_value) AS min_value,
  MAX(metric_value) AS max_value,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY metric_value) AS p50_value,
  PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY metric_value) AS p95_value,
  PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY metric_value) AS p99_value,
  COUNT(*) AS sample_count
FROM performance_metrics
WHERE created_at >= NOW() - INTERVAL '7 days'
GROUP BY DATE_TRUNC('hour', created_at), service, metric_type, metric_name
ORDER BY hour DESC;

-- 9. 授权
GRANT SELECT, INSERT ON performance_metrics TO authenticated;
GRANT SELECT ON slow_queries TO authenticated;
GRANT EXECUTE ON FUNCTION get_performance_stats TO authenticated;
GRANT EXECUTE ON FUNCTION get_slow_queries_stats TO authenticated;
GRANT SELECT ON performance_summary TO authenticated;

-- 10. RLS 策略
ALTER TABLE performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE slow_queries ENABLE ROW LEVEL SECURITY;

-- 允许服务角色完全访问
CREATE POLICY "Service role can manage performance metrics"
ON performance_metrics
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- 允许认证用户读取
CREATE POLICY "Authenticated users can read performance metrics"
ON performance_metrics
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Authenticated users can read slow queries"
ON slow_queries
FOR SELECT
TO authenticated
USING (true);

COMMENT ON TABLE performance_metrics IS '性能指标表，记录各服务的性能数据';
COMMENT ON TABLE slow_queries IS '慢查询日志表，记录执行时间超过阈值的查询';
COMMENT ON FUNCTION get_performance_stats IS '获取 API 性能统计，包括平均响应时间、百分位数、错误率等';
COMMENT ON FUNCTION get_slow_queries_stats IS '获取慢查询统计，按查询模式聚合';
