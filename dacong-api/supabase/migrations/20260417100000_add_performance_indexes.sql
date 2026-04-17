-- 性能优化索引迁移
-- 创建时间: 2026-04-17

-- ============================================
-- 1. 内容表索引优化
-- ============================================

-- 热门内容查询索引（按热度和时间排序）
CREATE INDEX IF NOT EXISTS idx_contents_hot_rank 
ON contents(hot_rank DESC, created_at DESC) 
WHERE status = 'published';

-- 分类查询索引
CREATE INDEX IF NOT EXISTS idx_contents_category 
ON contents(category, created_at DESC) 
WHERE status = 'published';

-- 标签查询索引（GIN 索引支持数组查询）
CREATE INDEX IF NOT EXISTS idx_contents_tags 
ON contents USING GIN(tags);

-- 全文搜索索引
CREATE INDEX IF NOT EXISTS idx_contents_search 
ON contents USING GIN(to_tsvector('chinese', title || ' ' || COALESCE(summary, '')));

-- 来源查询索引
CREATE INDEX IF NOT EXISTS idx_contents_source 
ON contents(source_platform, created_at DESC);

-- ============================================
-- 2. 用户行为表索引优化
-- ============================================

-- 用户浏览历史索引
CREATE INDEX IF NOT EXISTS idx_user_views_user_time 
ON user_views(user_id, viewed_at DESC);

-- 内容浏览统计索引
CREATE INDEX IF NOT EXISTS idx_user_views_content 
ON user_views(content_id, viewed_at DESC);

-- 用户收藏索引
CREATE INDEX IF NOT EXISTS idx_user_favorites_user 
ON user_favorites(user_id, created_at DESC);

-- 用户反馈索引
CREATE INDEX IF NOT EXISTS idx_user_feedback_content 
ON user_feedback(content_id, created_at DESC);

-- ============================================
-- 3. AI 模型表索引优化
-- ============================================

-- 模型排名索引
CREATE INDEX IF NOT EXISTS idx_ai_models_rank 
ON ai_models(overall_rank ASC) 
WHERE status = 'active';

-- 模型分类索引
CREATE INDEX IF NOT EXISTS idx_ai_models_category 
ON ai_models(category, overall_rank ASC);

-- 模型能力标签索引
CREATE INDEX IF NOT EXISTS idx_ai_models_capabilities 
ON ai_models USING GIN(capabilities);

-- ============================================
-- 4. 推荐表索引优化
-- ============================================

-- 用户推荐索引
CREATE INDEX IF NOT EXISTS idx_recommendations_user 
ON recommendations(user_id, created_at DESC);

-- 推荐场景索引
CREATE INDEX IF NOT EXISTS idx_recommendations_scenario 
ON recommendations(scenario, created_at DESC);

-- ============================================
-- 5. 复合索引优化
-- ============================================

-- 用户内容交互复合索引
CREATE INDEX IF NOT EXISTS idx_user_content_interaction 
ON user_views(user_id, content_id, viewed_at DESC);

-- 内容统计复合索引
CREATE INDEX IF NOT EXISTS idx_contents_stats 
ON contents(view_count DESC, like_count DESC, created_at DESC) 
WHERE status = 'published';

-- ============================================
-- 6. 分区表索引（如果数据量大）
-- ============================================

-- 为历史数据创建分区索引
-- CREATE INDEX IF NOT EXISTS idx_user_views_2026_q1 
-- ON user_views_2026_q1(user_id, viewed_at DESC);

-- ============================================
-- 7. 统计信息更新
-- ============================================

-- 更新表统计信息以优化查询计划
ANALYZE contents;
ANALYZE user_views;
ANALYZE user_favorites;
ANALYZE ai_models;
ANALYZE recommendations;

-- ============================================
-- 8. 索引维护建议
-- ============================================

-- 定期重建索引以保持性能
-- REINDEX TABLE contents;
-- REINDEX TABLE user_views;

COMMENT ON INDEX idx_contents_hot_rank IS '热门内容查询优化索引';
COMMENT ON INDEX idx_contents_search IS '全文搜索优化索引';
COMMENT ON INDEX idx_user_views_user_time IS '用户浏览历史优化索引';
COMMENT ON INDEX idx_ai_models_rank IS '模型排名查询优化索引';
