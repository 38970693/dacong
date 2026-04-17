-- 数据库验证脚本
-- 用途：验证表结构、索引、触发器、RLS策略

-- ============================================
-- 1. 验证表是否存在
-- ============================================
SELECT
  table_name,
  CASE
    WHEN table_name IN ('raw_data', 'generated_content', 'published_content', 'user_feedback', 'scenario_recommendations', 'spider_logs')
    THEN '✓ 存在'
    ELSE '✗ 缺失'
  END AS status
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- ============================================
-- 2. 验证索引
-- ============================================
SELECT
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- ============================================
-- 3. 验证触发器
-- ============================================
SELECT
  trigger_name,
  event_object_table AS table_name,
  action_timing,
  event_manipulation,
  action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- ============================================
-- 4. 验证 RLS 策略
-- ============================================
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ============================================
-- 5. 验证视图
-- ============================================
SELECT
  table_name AS view_name,
  view_definition
FROM information_schema.views
WHERE table_schema = 'public'
ORDER BY table_name;

-- ============================================
-- 6. 验证外键约束
-- ============================================
SELECT
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name,
  tc.constraint_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;

-- ============================================
-- 7. 验证 CHECK 约束
-- ============================================
SELECT
  tc.table_name,
  tc.constraint_name,
  cc.check_clause
FROM information_schema.table_constraints AS tc
JOIN information_schema.check_constraints AS cc
  ON tc.constraint_name = cc.constraint_name
WHERE tc.constraint_type = 'CHECK'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_name;

-- ============================================
-- 8. 表大小统计
-- ============================================
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
  pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) AS indexes_size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- ============================================
-- 9. 数据统计
-- ============================================
SELECT 'raw_data' AS table_name, COUNT(*) AS row_count FROM raw_data
UNION ALL
SELECT 'generated_content', COUNT(*) FROM generated_content
UNION ALL
SELECT 'published_content', COUNT(*) FROM published_content
UNION ALL
SELECT 'user_feedback', COUNT(*) FROM user_feedback
UNION ALL
SELECT 'scenario_recommendations', COUNT(*) FROM scenario_recommendations
UNION ALL
SELECT 'spider_logs', COUNT(*) FROM spider_logs
ORDER BY table_name;

-- ============================================
-- 10. 测试触发器
-- ============================================
-- 测试 updated_at 自动更新
DO $$
DECLARE
  test_id UUID;
  old_updated_at TIMESTAMPTZ;
  new_updated_at TIMESTAMPTZ;
BEGIN
  -- 插入测试数据
  INSERT INTO published_content (content_type, title_zh, content_zh)
  VALUES ('recommendation', '测试标题', '{"test": true}'::jsonb)
  RETURNING id, updated_at INTO test_id, old_updated_at;

  -- 等待1秒
  PERFORM pg_sleep(1);

  -- 更新数据
  UPDATE published_content
  SET title_zh = '测试标题（已更新）'
  WHERE id = test_id
  RETURNING updated_at INTO new_updated_at;

  -- 验证 updated_at 是否自动更新
  IF new_updated_at > old_updated_at THEN
    RAISE NOTICE '✓ updated_at 触发器工作正常';
  ELSE
    RAISE EXCEPTION '✗ updated_at 触发器未生效';
  END IF;

  -- 清理测试数据
  DELETE FROM published_content WHERE id = test_id;
END $$;

-- ============================================
-- 11. 测试 RLS 策略
-- ============================================
-- 注意：需要在不同的角色下测试
-- 这里只是列出测试命令，实际需要手动执行

-- 测试匿名用户可以查看 published_content
-- SET ROLE anon;
-- SELECT COUNT(*) FROM published_content;
-- RESET ROLE;

-- 测试匿名用户不能修改 published_content
-- SET ROLE anon;
-- UPDATE published_content SET title_zh = 'hack' WHERE id = '...';  -- 应该失败
-- RESET ROLE;

RAISE NOTICE '========================================';
RAISE NOTICE '数据库验证完成！';
RAISE NOTICE '请检查上述输出，确保所有表、索引、触发器、RLS策略都已正确创建';
RAISE NOTICE '========================================';
