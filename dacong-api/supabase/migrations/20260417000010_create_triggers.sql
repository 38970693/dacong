-- Migration: Create triggers
-- Description: 自动更新时间戳和统计数据

-- 1. 自动更新 updated_at 触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 应用到 generated_content
CREATE TRIGGER update_generated_content_updated_at
BEFORE UPDATE ON generated_content
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 应用到 published_content
CREATE TRIGGER update_published_content_updated_at
BEFORE UPDATE ON published_content
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 应用到 scenario_recommendations
CREATE TRIGGER update_scenario_recommendations_updated_at
BEFORE UPDATE ON scenario_recommendations
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 2. 自动更新内容统计触发器函数
CREATE OR REPLACE FUNCTION update_content_stats()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_helpful THEN
    UPDATE published_content
    SET helpful_count = helpful_count + 1
    WHERE id = NEW.content_id;
  ELSE
    UPDATE published_content
    SET unhelpful_count = unhelpful_count + 1
    WHERE id = NEW.content_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 应用到 user_feedback
CREATE TRIGGER update_content_stats_on_feedback
AFTER INSERT ON user_feedback
FOR EACH ROW
EXECUTE FUNCTION update_content_stats();

-- 3. 自动计算爬虫运行时长
CREATE OR REPLACE FUNCTION calculate_spider_duration()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.finished_at IS NOT NULL AND NEW.started_at IS NOT NULL THEN
    NEW.duration_seconds = EXTRACT(EPOCH FROM (NEW.finished_at - NEW.started_at))::INT;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_spider_duration_trigger
BEFORE UPDATE ON spider_logs
FOR EACH ROW
WHEN (NEW.finished_at IS NOT NULL AND OLD.finished_at IS NULL)
EXECUTE FUNCTION calculate_spider_duration();
