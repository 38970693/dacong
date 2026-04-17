-- ============================================
-- 测试数据初始化脚本
-- ============================================
-- 用途：为测试环境初始化基础数据
-- 使用：psql $DATABASE_URL -f scripts/init_test_data.sql

BEGIN;

-- ============================================
-- 1. 清理现有测试数据（可选）
-- ============================================
-- DELETE FROM user_feedback WHERE user_id LIKE 'test-%';
-- DELETE FROM scenario_recommendations WHERE user_id LIKE 'test-%';

-- ============================================
-- 2. 插入测试内容
-- ============================================

-- 插入原始数据
INSERT INTO raw_data (source, source_url, title, content, author, tags, metadata)
VALUES
  ('github', 'https://github.com/test/repo1', 'Test Repository 1', 'This is a test repository for testing purposes.', 'test-author', ARRAY['test', 'demo'], '{"stars": 100, "language": "TypeScript"}'::jsonb),
  ('github', 'https://github.com/test/repo2', 'Test Repository 2', 'Another test repository with more features.', 'test-author', ARRAY['test', 'example'], '{"stars": 200, "language": "Python"}'::jsonb),
  ('github', 'https://github.com/test/repo3', 'Test Repository 3', 'Advanced test repository for integration testing.', 'test-author', ARRAY['test', 'integration'], '{"stars": 300, "language": "Go"}'::jsonb)
ON CONFLICT (source_url) DO NOTHING;

-- 获取插入的原始数据 ID
DO $$
DECLARE
  raw_id_1 UUID;
  raw_id_2 UUID;
  raw_id_3 UUID;
  gen_id_1 UUID;
  gen_id_2 UUID;
  gen_id_3 UUID;
BEGIN
  -- 获取原始数据 ID
  SELECT id INTO raw_id_1 FROM raw_data WHERE source_url = 'https://github.com/test/repo1';
  SELECT id INTO raw_id_2 FROM raw_data WHERE source_url = 'https://github.com/test/repo2';
  SELECT id INTO raw_id_3 FROM raw_data WHERE source_url = 'https://github.com/test/repo3';

  -- 插入生成内容
  INSERT INTO generated_content (raw_data_id, title, summary, highlights, tags, quality_score)
  VALUES
    (raw_id_1, 'Test Repository 1 - 测试仓库', '这是一个用于测试的示例仓库，包含基础功能。', ARRAY['TypeScript 实现', '100+ stars', '活跃维护'], ARRAY['测试', '演示'], 0.85),
    (raw_id_2, 'Test Repository 2 - 功能丰富', '功能更丰富的测试仓库，适合学习参考。', ARRAY['Python 实现', '200+ stars', '文档完善'], ARRAY['测试', '示例'], 0.90),
    (raw_id_3, 'Test Repository 3 - 高级特性', '包含高级特性的测试仓库，用于集成测试。', ARRAY['Go 实现', '300+ stars', '性能优秀'], ARRAY['测试', '集成'], 0.95)
  ON CONFLICT DO NOTHING
  RETURNING id INTO gen_id_1, gen_id_2, gen_id_3;

  -- 插入发布内容
  INSERT INTO published_content (generated_content_id, title, summary, content, tags, category, view_count, like_count, share_count)
  VALUES
    (gen_id_1, 'Test Repository 1 - 测试仓库', '这是一个用于测试的示例仓库，包含基础功能。', '{"highlights": ["TypeScript 实现", "100+ stars", "活跃维护"], "source_url": "https://github.com/test/repo1"}'::jsonb, ARRAY['测试', '演示'], 'tech', 100, 10, 5),
    (gen_id_2, 'Test Repository 2 - 功能丰富', '功能更丰富的测试仓库，适合学习参考。', '{"highlights": ["Python 实现", "200+ stars", "文档完善"], "source_url": "https://github.com/test/repo2"}'::jsonb, ARRAY['测试', '示例'], 'tech', 200, 20, 10),
    (gen_id_3, 'Test Repository 3 - 高级特性', '包含高级特性的测试仓库，用于集成测试。', '{"highlights": ["Go 实现", "300+ stars", "性能优秀"], "source_url": "https://github.com/test/repo3"}'::jsonb, ARRAY['测试', '集成'], 'tech', 300, 30, 15)
  ON CONFLICT DO NOTHING;
END $$;

-- ============================================
-- 3. 插入测试用户反馈
-- ============================================

INSERT INTO user_feedback (user_id, content_id, feedback_type, rating, comment)
SELECT
  'test-user-1',
  id,
  'like',
  5,
  'Great content!'
FROM published_content
WHERE title LIKE 'Test Repository%'
LIMIT 1
ON CONFLICT DO NOTHING;

INSERT INTO user_feedback (user_id, content_id, feedback_type, rating, comment)
SELECT
  'test-user-2',
  id,
  'view',
  NULL,
  NULL
FROM published_content
WHERE title LIKE 'Test Repository%'
LIMIT 2
ON CONFLICT DO NOTHING;

-- ============================================
-- 4. 插入场景推荐
-- ============================================

INSERT INTO scenario_recommendations (user_id, scenario, content_ids, metadata)
SELECT
  'test-user-1',
  'morning',
  ARRAY_AGG(id),
  '{"reason": "test data"}'::jsonb
FROM published_content
WHERE title LIKE 'Test Repository%'
ON CONFLICT (user_id, scenario) DO UPDATE
SET content_ids = EXCLUDED.content_ids,
    metadata = EXCLUDED.metadata,
    updated_at = NOW();

-- ============================================
-- 5. 插入测试评论
-- ============================================

INSERT INTO comments (content_id, user_id, content, parent_id)
SELECT
  id,
  'test-user-1',
  'This is a test comment.',
  NULL
FROM published_content
WHERE title LIKE 'Test Repository 1%'
LIMIT 1
ON CONFLICT DO NOTHING;

INSERT INTO comments (content_id, user_id, content, parent_id)
SELECT
  pc.id,
  'test-user-2',
  'This is a reply to the test comment.',
  c.id
FROM published_content pc
CROSS JOIN comments c
WHERE pc.title LIKE 'Test Repository 1%'
  AND c.user_id = 'test-user-1'
  AND c.parent_id IS NULL
LIMIT 1
ON CONFLICT DO NOTHING;

-- ============================================
-- 6. 验证数据
-- ============================================

DO $$
DECLARE
  raw_count INT;
  gen_count INT;
  pub_count INT;
  feedback_count INT;
  comment_count INT;
BEGIN
  SELECT COUNT(*) INTO raw_count FROM raw_data WHERE source_url LIKE '%test%';
  SELECT COUNT(*) INTO gen_count FROM generated_content WHERE title LIKE 'Test Repository%';
  SELECT COUNT(*) INTO pub_count FROM published_content WHERE title LIKE 'Test Repository%';
  SELECT COUNT(*) INTO feedback_count FROM user_feedback WHERE user_id LIKE 'test-%';
  SELECT COUNT(*) INTO comment_count FROM comments WHERE user_id LIKE 'test-%';

  RAISE NOTICE '============================================';
  RAISE NOTICE '测试数据初始化完成';
  RAISE NOTICE '============================================';
  RAISE NOTICE '原始数据: % 条', raw_count;
  RAISE NOTICE '生成内容: % 条', gen_count;
  RAISE NOTICE '发布内容: % 条', pub_count;
  RAISE NOTICE '用户反馈: % 条', feedback_count;
  RAISE NOTICE '评论数据: % 条', comment_count;
  RAISE NOTICE '============================================';
END $$;

COMMIT;
