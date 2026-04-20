-- Database Constraints Migration
-- 添加数据库约束以确保数据完整性和安全性

-- ============================================
-- 用户表约束
-- ============================================

-- 邮箱格式约束
ALTER TABLE users
ADD CONSTRAINT users_email_format
CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$');

-- 用户名格式约束
ALTER TABLE users
ADD CONSTRAINT users_username_format
CHECK (username ~* '^[a-zA-Z0-9_-]{3,30}$');

-- 用户名长度约束
ALTER TABLE users
ADD CONSTRAINT users_username_length
CHECK (char_length(username) BETWEEN 3 AND 30);

-- ============================================
-- 用户资料表约束
-- ============================================

-- 显示名称长度约束
ALTER TABLE profiles
ADD CONSTRAINT profiles_display_name_length
CHECK (display_name IS NULL OR char_length(display_name) BETWEEN 1 AND 50);

-- 个人简介长度约束
ALTER TABLE profiles
ADD CONSTRAINT profiles_bio_length
CHECK (bio IS NULL OR char_length(bio) <= 500);

-- 位置长度约束
ALTER TABLE profiles
ADD CONSTRAINT profiles_location_length
CHECK (location IS NULL OR char_length(location) <= 100);

-- 网站 URL 格式约束
ALTER TABLE profiles
ADD CONSTRAINT profiles_website_format
CHECK (website IS NULL OR website ~* '^https?://[^\s]+$');

-- 头像 URL 格式约束（仅 HTTPS）
ALTER TABLE profiles
ADD CONSTRAINT profiles_avatar_url_format
CHECK (avatar_url IS NULL OR avatar_url ~* '^https://[^\s]+$');

-- ============================================
-- 内容表约束
-- ============================================

-- 标题长度约束
ALTER TABLE contents
ADD CONSTRAINT contents_title_length
CHECK (char_length(title) BETWEEN 1 AND 200);

-- 描述长度约束
ALTER TABLE contents
ADD CONSTRAINT contents_description_length
CHECK (description IS NULL OR char_length(description) <= 2000);

-- 内容长度约束
ALTER TABLE contents
ADD CONSTRAINT contents_content_length
CHECK (content IS NULL OR char_length(content) <= 50000);

-- URL 格式约束
ALTER TABLE contents
ADD CONSTRAINT contents_url_format
CHECK (url IS NULL OR url ~* '^https?://[^\s]+$');

-- 图片 URL 格式约束（仅 HTTPS）
ALTER TABLE contents
ADD CONSTRAINT contents_image_url_format
CHECK (image_url IS NULL OR image_url ~* '^https://[^\s]+$');

-- 状态枚举约束
ALTER TABLE contents
ADD CONSTRAINT contents_status_check
CHECK (status IN ('draft', 'published', 'archived', 'pending', 'approved', 'rejected'));

-- ============================================
-- 评论表约束
-- ============================================

-- 评论内容长度约束
ALTER TABLE comments
ADD CONSTRAINT comments_content_length
CHECK (char_length(content) BETWEEN 1 AND 1000);

-- 点赞数非负约束
ALTER TABLE comments
ADD CONSTRAINT comments_likes_count_positive
CHECK (likes_count >= 0);

-- 状态枚举约束
ALTER TABLE comments
ADD CONSTRAINT comments_status_check
CHECK (status IN ('pending', 'approved', 'rejected', 'flagged'));

-- ============================================
-- 标签表约束
-- ============================================

-- 标签名称长度约束
ALTER TABLE tags
ADD CONSTRAINT tags_name_length
CHECK (char_length(name) BETWEEN 1 AND 30);

-- 标签名称格式约束（字母、数字、连字符、下划线）
ALTER TABLE tags
ADD CONSTRAINT tags_name_format
CHECK (name ~* '^[a-zA-Z0-9\-_]+$');

-- Slug 格式约束
ALTER TABLE tags
ADD CONSTRAINT tags_slug_format
CHECK (slug ~* '^[a-z0-9]+(?:-[a-z0-9]+)*$');

-- ============================================
-- 反馈表约束
-- ============================================

-- 反馈类型枚举约束
ALTER TABLE user_feedback
ADD CONSTRAINT user_feedback_type_check
CHECK (feedback_type IN ('helpful', 'not_helpful', 'report', 'suggestion'));

-- 评分范围约束
ALTER TABLE user_feedback
ADD CONSTRAINT user_feedback_rating_range
CHECK (rating IS NULL OR (rating >= 1 AND rating <= 5));

-- 评论长度约束
ALTER TABLE user_feedback
ADD CONSTRAINT user_feedback_comment_length
CHECK (comment IS NULL OR char_length(comment) <= 500);

-- ============================================
-- 举报表约束
-- ============================================

-- 举报原因枚举约束
ALTER TABLE reports
ADD CONSTRAINT reports_reason_check
CHECK (reason IN ('spam', 'harassment', 'hate_speech', 'violence', 'misinformation', 'other'));

-- 描述长度约束
ALTER TABLE reports
ADD CONSTRAINT reports_description_length
CHECK (description IS NULL OR char_length(description) <= 500);

-- 状态枚举约束
ALTER TABLE reports
ADD CONSTRAINT reports_status_check
CHECK (status IN ('pending', 'reviewed', 'resolved', 'dismissed'));

-- ============================================
-- 审计日志表约束
-- ============================================

-- 操作类型长度约束
ALTER TABLE audit_logs
ADD CONSTRAINT audit_logs_action_length
CHECK (char_length(action) BETWEEN 1 AND 100);

-- 资源类型长度约束
ALTER TABLE audit_logs
ADD CONSTRAINT audit_logs_resource_type_length
CHECK (resource_type IS NULL OR char_length(resource_type) <= 100);

-- IP 地址格式约束（IPv4 或 IPv6）
ALTER TABLE audit_logs
ADD CONSTRAINT audit_logs_ip_address_format
CHECK (
  ip_address IS NULL OR
  ip_address ~* '^(\d{1,3}\.){3}\d{1,3}$' OR  -- IPv4
  ip_address ~* '^([0-9a-f]{1,4}:){7}[0-9a-f]{1,4}$'  -- IPv6
);

-- ============================================
-- 通知表约束
-- ============================================

-- 通知类型枚举约束
ALTER TABLE notifications
ADD CONSTRAINT notifications_type_check
CHECK (type IN ('comment', 'like', 'mention', 'follow', 'system', 'moderation'));

-- 标题长度约束
ALTER TABLE notifications
ADD CONSTRAINT notifications_title_length
CHECK (char_length(title) BETWEEN 1 AND 200);

-- 内容长度约束
ALTER TABLE notifications
ADD CONSTRAINT notifications_content_length
CHECK (content IS NULL OR char_length(content) <= 1000);

-- ============================================
-- 用户封禁表约束
-- ============================================

-- 封禁原因长度约束
ALTER TABLE user_bans
ADD CONSTRAINT user_bans_reason_length
CHECK (char_length(reason) BETWEEN 1 AND 500);

-- 封禁时长约束（小时数，最多 365 天）
ALTER TABLE user_bans
ADD CONSTRAINT user_bans_duration_range
CHECK (duration_hours IS NULL OR (duration_hours > 0 AND duration_hours <= 8760));

-- 结束时间必须晚于开始时间
ALTER TABLE user_bans
ADD CONSTRAINT user_bans_end_after_start
CHECK (expires_at IS NULL OR expires_at > created_at);

-- ============================================
-- 搜索历史表约束
-- ============================================

-- 搜索查询长度约束
ALTER TABLE search_history
ADD CONSTRAINT search_history_query_length
CHECK (char_length(query) BETWEEN 1 AND 200);

-- ============================================
-- 分享记录表约束
-- ============================================

-- 分享平台枚举约束
ALTER TABLE shares
ADD CONSTRAINT shares_platform_check
CHECK (platform IN ('wechat', 'weibo', 'qq', 'twitter', 'facebook', 'link', 'other'));

-- ============================================
-- 索引优化（提高查询性能）
-- ============================================

-- 用户表索引
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

-- 内容表索引
CREATE INDEX IF NOT EXISTS idx_contents_status ON contents(status);
CREATE INDEX IF NOT EXISTS idx_contents_created_at ON contents(created_at);
CREATE INDEX IF NOT EXISTS idx_contents_user_id ON contents(user_id);
CREATE INDEX IF NOT EXISTS idx_contents_title_gin ON contents USING gin(to_tsvector('english', title));

-- 评论表索引
CREATE INDEX IF NOT EXISTS idx_comments_content_id ON comments(content_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON comments(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_parent_id ON comments(parent_id);
CREATE INDEX IF NOT EXISTS idx_comments_status ON comments(status);
CREATE INDEX IF NOT EXISTS idx_comments_created_at ON comments(created_at);

-- 标签表索引
CREATE INDEX IF NOT EXISTS idx_tags_name ON tags(name);
CREATE INDEX IF NOT EXISTS idx_tags_slug ON tags(slug);

-- 审计日志表索引
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);

-- 通知表索引
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);

-- ============================================
-- 注释
-- ============================================

COMMENT ON CONSTRAINT users_email_format ON users IS '邮箱格式验证';
COMMENT ON CONSTRAINT users_username_format ON users IS '用户名格式验证（字母、数字、下划线、连字符）';
COMMENT ON CONSTRAINT contents_title_length ON contents IS '标题长度限制（1-200字符）';
COMMENT ON CONSTRAINT comments_content_length ON comments IS '评论长度限制（1-1000字符）';
COMMENT ON CONSTRAINT tags_name_format ON tags IS '标签名称格式验证';
