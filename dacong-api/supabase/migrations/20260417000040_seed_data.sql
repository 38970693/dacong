-- Migration: Seed data
-- Description: 插入测试数据

-- 注意：这个文件仅用于开发环境测试
-- 生产环境请勿运行此文件

-- 1. 插入测试原始数据
INSERT INTO raw_data (source, data_type, raw_json, processed) VALUES
('github', 'tool', '{
  "repo_url": "https://github.com/anthropics/claude-code",
  "name": "claude-code",
  "description": "AI coding assistant",
  "stars": 15000,
  "forks": 1200,
  "language": "Python",
  "topics": ["ai", "coding", "assistant"]
}'::jsonb, false),

('huggingface', 'model', '{
  "model_id": "meta-llama/Llama-3.1-405B",
  "downloads": 5000000,
  "likes": 12000,
  "tags": ["llm", "text-generation"],
  "model_size": "405B"
}'::jsonb, false);

-- 2. 插入测试生成内容
INSERT INTO generated_content (
  content_type,
  title_zh,
  summary_zh,
  content_zh,
  scenario,
  ai_confidence,
  quality_score,
  review_status
) VALUES
(
  'recommendation',
  '2026年最佳AI编程工具推荐',
  '精选5款最强AI编程助手，帮你10倍提升开发效率',
  '{
    "recommendations": [
      {
        "rank": 1,
        "name": "Claude Code",
        "one_liner": "代码能力最强的AI助手",
        "pros": ["代码质量高", "推理能力强"],
        "cons": ["价格较贵"],
        "best_for": "专业开发者",
        "price": "$20/月",
        "rating": 4.5
      }
    ]
  }'::jsonb,
  'coding',
  0.92,
  0.88,
  'pending'
);

-- 3. 插入测试已发布内容
INSERT INTO published_content (
  content_type,
  title_zh,
  summary_zh,
  content_zh,
  scenario,
  view_count,
  helpful_count,
  unhelpful_count
) VALUES
(
  'recommendation',
  '2026年最佳AI编程工具推荐',
  '精选5款最强AI编程助手，帮你10倍提升开发效率',
  '{
    "recommendations": [
      {
        "rank": 1,
        "name": "Claude Code",
        "one_liner": "代码能力最强的AI助手",
        "pros": ["代码质量高", "推理能力强"],
        "cons": ["价格较贵"],
        "best_for": "专业开发者",
        "price": "$20/月",
        "rating": 4.5
      }
    ]
  }'::jsonb,
  'coding',
  1250,
  89,
  12
);

-- 4. 插入场景推荐配置
-- 注意：需要先获取 published_content 的 ID
DO $$
DECLARE
  coding_content_id UUID;
BEGIN
  SELECT id INTO coding_content_id
  FROM published_content
  WHERE scenario = 'coding'
  LIMIT 1;

  IF coding_content_id IS NOT NULL THEN
    INSERT INTO scenario_recommendations (scenario, rank, content_id, active)
    VALUES ('coding', 1, coding_content_id, true);
  END IF;
END $$;

-- 5. 插入爬虫日志
INSERT INTO spider_logs (
  spider_name,
  source,
  status,
  items_scraped,
  items_saved,
  items_failed,
  started_at,
  finished_at,
  duration_seconds
) VALUES
(
  'github_trending_spider',
  'github',
  'success',
  50,
  48,
  2,
  NOW() - INTERVAL '1 hour',
  NOW() - INTERVAL '55 minutes',
  300
);
