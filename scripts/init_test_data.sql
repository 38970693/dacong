-- ============================================
-- DaCong 测试数据初始化脚本
-- ============================================
-- 用途: 为测试环境创建初始数据
-- 使用: psql $DATABASE_URL -f scripts/init_test_data.sql

BEGIN;

-- ============================================
-- 清理现有测试数据（可选）
-- ============================================
-- 注意: 仅在测试环境使用！
-- TRUNCATE TABLE user_feedback CASCADE;
-- TRUNCATE TABLE published_content CASCADE;
-- TRUNCATE TABLE generated_content CASCADE;
-- TRUNCATE TABLE raw_data CASCADE;
-- TRUNCATE TABLE spider_logs CASCADE;

-- ============================================
-- 插入测试原始数据
-- ============================================
INSERT INTO raw_data (source, source_type, title, url, content, metadata, tags)
VALUES
    -- GitHub 热门项目
    (
        'github',
        'repository',
        'awesome-ai-tools',
        'https://github.com/test/awesome-ai-tools',
        '一个收集最新 AI 工具的仓库，包含 ChatGPT、Midjourney 等热门工具的使用指南。',
        '{"stars": 15000, "language": "Python", "topics": ["ai", "tools", "chatgpt"]}'::jsonb,
        ARRAY['AI', '工具', 'ChatGPT']
    ),
    (
        'github',
        'repository',
        'flutter-best-practices',
        'https://github.com/test/flutter-best-practices',
        'Flutter 开发最佳实践集合，涵盖状态管理、性能优化、架构设计等主题。',
        '{"stars": 8000, "language": "Dart", "topics": ["flutter", "mobile", "best-practices"]}'::jsonb,
        ARRAY['Flutter', '移动开发', '最佳实践']
    ),

    -- 技术博客
    (
        'blog',
        'article',
        '深入理解 React Server Components',
        'https://blog.example.com/react-server-components',
        'React Server Components 是 React 18 引入的新特性，本文深入解析其工作原理和使用场景。',
        '{"author": "张三", "publish_date": "2026-04-15", "read_time": 10}'::jsonb,
        ARRAY['React', '前端', 'Server Components']
    ),
    (
        'blog',
        'article',
        'Kubernetes 生产环境最佳实践',
        'https://blog.example.com/k8s-production',
        '分享在生产环境中运行 Kubernetes 的经验，包括监控、日志、安全等方面的最佳实践。',
        '{"author": "李四", "publish_date": "2026-04-14", "read_time": 15}'::jsonb,
        ARRAY['Kubernetes', 'DevOps', '运维']
    ),

    -- 技术新闻
    (
        'news',
        'article',
        'OpenAI 发布 GPT-5 预览版',
        'https://news.example.com/gpt5-preview',
        'OpenAI 今日发布 GPT-5 预览版，性能相比 GPT-4 提升 50%，支持更长的上下文窗口。',
        '{"source": "TechCrunch", "publish_date": "2026-04-16"}'::jsonb,
        ARRAY['AI', 'OpenAI', 'GPT-5']
    )
ON CONFLICT (url) DO NOTHING;

-- ============================================
-- 插入测试生成内容
-- ============================================
INSERT INTO generated_content (raw_data_id, content_type, title, summary, full_content, target_audience, tags)
SELECT
    id,
    'weekly_digest',
    '本周技术热点：' || title,
    '本周' || source_type || '热点内容精选',
    '## ' || title || E'\n\n' || content || E'\n\n### 推荐理由\n\n这是一个值得关注的' || source_type || '，适合对' || tags[1] || '感兴趣的开发者。',
    CASE
        WHEN 'AI' = ANY(tags) THEN 'ai_enthusiast'
        WHEN 'Flutter' = ANY(tags) THEN 'mobile_developer'
        WHEN 'React' = ANY(tags) THEN 'frontend_developer'
        WHEN 'Kubernetes' = ANY(tags) THEN 'devops_engineer'
        ELSE 'general_developer'
    END,
    tags
FROM raw_data
WHERE created_at > NOW() - INTERVAL '7 days'
ON CONFLICT DO NOTHING;

-- ============================================
-- 插入测试发布内容
-- ============================================
INSERT INTO published_content (generated_content_id, publish_date, view_count, like_count, share_count)
SELECT
    id,
    CURRENT_DATE,
    FLOOR(RANDOM() * 1000)::int,
    FLOOR(RANDOM() * 100)::int,
    FLOOR(RANDOM() * 50)::int
FROM generated_content
WHERE status = 'approved'
ON CONFLICT DO NOTHING;

-- ============================================
-- 插入测试用户反馈
-- ============================================
INSERT INTO user_feedback (published_content_id, user_id, feedback_type, rating, comment)
SELECT
    pc.id,
    'test-user-' || (RANDOM() * 100)::int,
    CASE (RANDOM() * 3)::int
        WHEN 0 THEN 'like'
        WHEN 1 THEN 'dislike'
        ELSE 'report'
    END,
    (RANDOM() * 5)::int + 1,
    '这是一条测试反馈'
FROM published_content pc
LIMIT 10
ON CONFLICT DO NOTHING;

-- ============================================
-- 插入测试爬虫日志
-- ============================================
INSERT INTO spider_logs (spider_name, status, items_scraped, error_message, metadata)
VALUES
    ('github_spider', 'success', 50, NULL, '{"duration_seconds": 120, "api_calls": 10}'::jsonb),
    ('blog_spider', 'success', 30, NULL, '{"duration_seconds": 90, "pages_crawled": 5}'::jsonb),
    ('news_spider', 'failed', 0, 'Connection timeout', '{"duration_seconds": 30, "retry_count": 3}'::jsonb)
ON CONFLICT DO NOTHING;

-- ============================================
-- 更新统计信息
-- ============================================
-- 刷新物化视图（如果有）
-- REFRESH MATERIALIZED VIEW IF EXISTS content_stats;

-- 更新序列（确保 ID 不冲突）
SELECT setval('raw_data_id_seq', (SELECT MAX(id) FROM raw_data));
SELECT setval('generated_content_id_seq', (SELECT MAX(id) FROM generated_content));
SELECT setval('published_content_id_seq', (SELECT MAX(id) FROM published_content));
SELECT setval('user_feedback_id_seq', (SELECT MAX(id) FROM user_feedback));
SELECT setval('spider_logs_id_seq', (SELECT MAX(id) FROM spider_logs));

COMMIT;

-- ============================================
-- 验证数据
-- ============================================
DO $$
DECLARE
    raw_count int;
    generated_count int;
    published_count int;
BEGIN
    SELECT COUNT(*) INTO raw_count FROM raw_data;
    SELECT COUNT(*) INTO generated_count FROM generated_content;
    SELECT COUNT(*) INTO published_count FROM published_content;

    RAISE NOTICE '测试数据初始化完成:';
    RAISE NOTICE '  - 原始数据: % 条', raw_count;
    RAISE NOTICE '  - 生成内容: % 条', generated_count;
    RAISE NOTICE '  - 发布内容: % 条', published_count;
END $$;
