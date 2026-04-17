-- 性能优化：添加数据库索引

-- 用户表索引
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_users_last_login_at ON users(last_login_at DESC);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- 内容表索引
CREATE INDEX IF NOT EXISTS idx_contents_author_id ON contents(author_id);
CREATE INDEX IF NOT EXISTS idx_contents_status ON contents(status);
CREATE INDEX IF NOT EXISTS idx_contents_created_at ON contents(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_contents_published_at ON contents(published_at DESC);
CREATE INDEX IF NOT EXISTS idx_contents_views ON contents(views DESC);
CREATE INDEX IF NOT EXISTS idx_contents_likes ON contents(likes DESC);

-- 复合索引：状态 + 浏览量（用于热门内容查询）
CREATE INDEX IF NOT EXISTS idx_contents_status_views ON contents(status, views DESC) WHERE status = 'published';

-- 评论表索引
CREATE INDEX IF NOT EXISTS idx_comments_content_id ON comments(content_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON comments(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_status ON comments(status);
CREATE INDEX IF NOT EXISTS idx_comments_created_at ON comments(created_at DESC);

-- 复合索引：内容ID + 状态（用于获取已发布评论）
CREATE INDEX IF NOT EXISTS idx_comments_content_status ON comments(content_id, status) WHERE status = 'published';

-- 搜索日志表索引
CREATE INDEX IF NOT EXISTS idx_search_logs_keyword ON search_logs(keyword);
CREATE INDEX IF NOT EXISTS idx_search_logs_created_at ON search_logs(created_at DESC);

-- 分析数据表索引
CREATE INDEX IF NOT EXISTS idx_analytics_daily_date ON analytics_daily(date DESC);

-- 通知表索引
CREATE INDEX IF NOT EXISTS idx_admin_notifications_timestamp ON admin_notifications(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_admin_notifications_is_read ON admin_notifications(is_read);

-- 点赞表索引
CREATE INDEX IF NOT EXISTS idx_likes_user_id ON likes(user_id);
CREATE INDEX IF NOT EXISTS idx_likes_content_id ON likes(content_id);
CREATE INDEX IF NOT EXISTS idx_likes_created_at ON likes(created_at DESC);

-- 复合索引：用户ID + 内容ID（用于检查是否已点赞）
CREATE INDEX IF NOT EXISTS idx_likes_user_content ON likes(user_id, content_id);

-- 收藏表索引
CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_content_id ON favorites(content_id);
CREATE INDEX IF NOT EXISTS idx_favorites_created_at ON favorites(created_at DESC);

-- 复合索引：用户ID + 内容ID（用于检查是否已收藏）
CREATE INDEX IF NOT EXISTS idx_favorites_user_content ON favorites(user_id, content_id);

-- 全文搜索索引（PostgreSQL）
CREATE INDEX IF NOT EXISTS idx_contents_title_search ON contents USING gin(to_tsvector('chinese', title));
CREATE INDEX IF NOT EXISTS idx_contents_content_search ON contents USING gin(to_tsvector('chinese', content));

-- 分析查询：查看索引使用情况
-- SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch
-- FROM pg_stat_user_indexes
-- ORDER BY idx_scan DESC;

-- 分析查询：查看表大小
-- SELECT schemaname, tablename,
--        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
-- FROM pg_tables
-- WHERE schemaname = 'public'
-- ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
