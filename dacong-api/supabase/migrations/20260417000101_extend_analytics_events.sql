-- 扩展 analytics_events 表支持更多事件类型
-- Created: 2026-04-17
-- Description: 为用户画像系统添加更多事件类型的支持

-- ============================================================================
-- 1. 添加事件类型约束和注释
-- ============================================================================

-- 更新事件类型注释，列出所有支持的事件类型
COMMENT ON COLUMN analytics_events.event_type IS '事件类型：
  - page_view: 页面浏览
  - content_view: 内容查看
  - content_click: 内容点击
  - search: 搜索行为
  - search_result_click: 搜索结果点击
  - favorite_add: 添加收藏
  - favorite_remove: 取消收藏
  - share: 分享内容
  - comment: 评论
  - comment_like: 点赞评论
  - feedback: 反馈（有用/无用）
  - session_start: 会话开始
  - session_end: 会话结束
  - scroll_depth: 滚动深度
  - read_time: 阅读时长
  - video_play: 视频播放
  - video_pause: 视频暂停
  - video_complete: 视频完成
  - link_click: 外链点击
  - download: 下载
  - error: 错误事件
';

-- ============================================================================
-- 2. 创建事件类型枚举（可选，用于类型检查）
-- ============================================================================

-- 注意：PostgreSQL 的枚举类型不易修改，这里使用注释和应用层验证
-- 如果需要严格的类型检查，可以创建一个事件类型表

CREATE TABLE IF NOT EXISTS event_types (
  event_type VARCHAR(50) PRIMARY KEY,
  category VARCHAR(50) NOT NULL,  -- 'navigation', 'content', 'interaction', 'system'
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 插入标准事件类型
INSERT INTO event_types (event_type, category, description) VALUES
  ('page_view', 'navigation', '页面浏览'),
  ('content_view', 'content', '内容查看'),
  ('content_click', 'content', '内容点击'),
  ('search', 'interaction', '搜索行为'),
  ('search_result_click', 'interaction', '搜索结果点击'),
  ('favorite_add', 'interaction', '添加收藏'),
  ('favorite_remove', 'interaction', '取消收藏'),
  ('share', 'interaction', '分享内容'),
  ('comment', 'interaction', '评论'),
  ('comment_like', 'interaction', '点赞评论'),
  ('feedback', 'interaction', '反馈（有用/无用）'),
  ('session_start', 'system', '会话开始'),
  ('session_end', 'system', '会话结束'),
  ('scroll_depth', 'content', '滚动深度'),
  ('read_time', 'content', '阅读时长'),
  ('video_play', 'content', '视频播放'),
  ('video_pause', 'content', '视频暂停'),
  ('video_complete', 'content', '视频完成'),
  ('link_click', 'navigation', '外链点击'),
  ('download', 'interaction', '下载'),
  ('error', 'system', '错误事件')
ON CONFLICT (event_type) DO NOTHING;

-- 索引
CREATE INDEX IF NOT EXISTS idx_event_types_category ON event_types(category);

-- ============================================================================
-- 3. 扩展触发器支持新事件类型
-- ============================================================================

-- 更新内容统计触发器，支持更多事件类型
CREATE OR REPLACE FUNCTION update_content_stats()
RETURNS TRIGGER AS $$
BEGIN
  -- 内容查看事件（包括 content_view 和 content_click）
  IF NEW.event_type IN ('content_view', 'content_click') AND NEW.content_id IS NOT NULL THEN
    INSERT INTO analytics_content (content_id, view_count, unique_view_count, last_viewed_at)
    VALUES (NEW.content_id, 1, 1, NEW.created_at)
    ON CONFLICT (content_id) DO UPDATE SET
      view_count = analytics_content.view_count + 1,
      last_viewed_at = NEW.created_at,
      updated_at = NOW();
  END IF;

  -- 阅读时长事件
  IF NEW.event_type = 'read_time' AND NEW.content_id IS NOT NULL THEN
    DECLARE
      v_read_time FLOAT;
    BEGIN
      v_read_time := (NEW.properties->>'duration')::float;
      IF v_read_time IS NOT NULL THEN
        UPDATE analytics_content
        SET avg_read_time = (
          CASE
            WHEN view_count > 0 THEN (avg_read_time * view_count + v_read_time) / (view_count + 1)
            ELSE v_read_time
          END
        ),
        updated_at = NOW()
        WHERE content_id = NEW.content_id;
      END IF;
    END;
  END IF;

  -- 收藏事件
  IF NEW.event_type = 'favorite_add' AND NEW.content_id IS NOT NULL THEN
    INSERT INTO analytics_content (content_id, favorite_count)
    VALUES (NEW.content_id, 1)
    ON CONFLICT (content_id) DO UPDATE SET
      favorite_count = analytics_content.favorite_count + 1,
      updated_at = NOW();
  END IF;

  -- 取消收藏事件
  IF NEW.event_type = 'favorite_remove' AND NEW.content_id IS NOT NULL THEN
    UPDATE analytics_content
    SET favorite_count = GREATEST(favorite_count - 1, 0),
        updated_at = NOW()
    WHERE content_id = NEW.content_id;
  END IF;

  -- 分享事件
  IF NEW.event_type = 'share' AND NEW.content_id IS NOT NULL THEN
    INSERT INTO analytics_content (content_id, share_count)
    VALUES (NEW.content_id, 1)
    ON CONFLICT (content_id) DO UPDATE SET
      share_count = analytics_content.share_count + 1,
      updated_at = NOW();
  END IF;

  -- 反馈事件
  IF NEW.event_type = 'feedback' AND NEW.content_id IS NOT NULL THEN
    IF (NEW.properties->>'is_helpful')::boolean THEN
      INSERT INTO analytics_content (content_id, helpful_count)
      VALUES (NEW.content_id, 1)
      ON CONFLICT (content_id) DO UPDATE SET
        helpful_count = analytics_content.helpful_count + 1,
        updated_at = NOW();
    ELSE
      INSERT INTO analytics_content (content_id, unhelpful_count)
      VALUES (NEW.content_id, 1)
      ON CONFLICT (content_id) DO UPDATE SET
        unhelpful_count = analytics_content.unhelpful_count + 1,
        updated_at = NOW();
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 4. 会话管理触发器
-- ============================================================================

-- 创建会话管理触发器函数
CREATE OR REPLACE FUNCTION manage_user_sessions()
RETURNS TRIGGER AS $$
BEGIN
  -- 会话开始事件
  IF NEW.event_type = 'session_start' AND NEW.user_id IS NOT NULL THEN
    INSERT INTO user_sessions (
      user_id,
      session_id,
      started_at,
      device_type,
      platform
    ) VALUES (
      NEW.user_id,
      NEW.session_id,
      NEW.created_at,
      NEW.device_info->>'device_type',
      NEW.device_info->>'platform'
    )
    ON CONFLICT DO NOTHING;
  END IF;

  -- 会话结束事件
  IF NEW.event_type = 'session_end' AND NEW.user_id IS NOT NULL THEN
    UPDATE user_sessions
    SET
      ended_at = NEW.created_at,
      duration = EXTRACT(EPOCH FROM (NEW.created_at - started_at))::int
    WHERE session_id = NEW.session_id
      AND ended_at IS NULL;
  END IF;

  -- 更新会话统计
  IF NEW.user_id IS NOT NULL THEN
    UPDATE user_sessions
    SET
      page_views = page_views + CASE WHEN NEW.event_type = 'page_view' THEN 1 ELSE 0 END,
      content_views = content_views + CASE WHEN NEW.event_type IN ('content_view', 'content_click') THEN 1 ELSE 0 END,
      searches = searches + CASE WHEN NEW.event_type = 'search' THEN 1 ELSE 0 END,
      interactions = interactions + CASE WHEN NEW.event_type IN ('favorite_add', 'share', 'comment') THEN 1 ELSE 0 END
    WHERE session_id = NEW.session_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 创建触发器
DROP TRIGGER IF EXISTS trigger_manage_user_sessions ON analytics_events;
CREATE TRIGGER trigger_manage_user_sessions
AFTER INSERT ON analytics_events
FOR EACH ROW EXECUTE FUNCTION manage_user_sessions();

-- ============================================================================
-- 5. 事件验证函数（可选）
-- ============================================================================

-- 创建事件验证函数
CREATE OR REPLACE FUNCTION validate_analytics_event()
RETURNS TRIGGER AS $$
BEGIN
  -- 验证事件类型是否存在
  IF NOT EXISTS (SELECT 1 FROM event_types WHERE event_type = NEW.event_type AND is_active = true) THEN
    RAISE WARNING 'Unknown or inactive event type: %', NEW.event_type;
  END IF;

  -- 验证必需字段
  IF NEW.event_type IN ('content_view', 'content_click', 'favorite_add', 'favorite_remove', 'share', 'feedback')
     AND NEW.content_id IS NULL THEN
    RAISE EXCEPTION 'content_id is required for event type: %', NEW.event_type;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 创建验证触发器（可选，如果需要严格验证）
-- DROP TRIGGER IF EXISTS trigger_validate_analytics_event ON analytics_events;
-- CREATE TRIGGER trigger_validate_analytics_event
-- BEFORE INSERT ON analytics_events
-- FOR EACH ROW EXECUTE FUNCTION validate_analytics_event();

-- ============================================================================
-- 6. 事件统计视图
-- ============================================================================

-- 6.1 事件类型统计视图
CREATE OR REPLACE VIEW v_event_type_stats AS
SELECT
  ae.event_type,
  et.category,
  et.description,
  COUNT(*) as event_count,
  COUNT(DISTINCT ae.user_id) as unique_users,
  COUNT(DISTINCT ae.session_id) as unique_sessions,
  MIN(ae.created_at) as first_seen,
  MAX(ae.created_at) as last_seen
FROM analytics_events ae
LEFT JOIN event_types et ON ae.event_type = et.event_type
WHERE ae.created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY ae.event_type, et.category, et.description
ORDER BY event_count DESC;

-- 6.2 用户行为漏斗视图
CREATE OR REPLACE VIEW v_user_funnel AS
SELECT
  COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) as page_viewers,
  COUNT(DISTINCT CASE WHEN event_type = 'content_view' THEN user_id END) as content_viewers,
  COUNT(DISTINCT CASE WHEN event_type = 'search' THEN user_id END) as searchers,
  COUNT(DISTINCT CASE WHEN event_type = 'favorite_add' THEN user_id END) as favoriters,
  COUNT(DISTINCT CASE WHEN event_type = 'share' THEN user_id END) as sharers,
  COUNT(DISTINCT CASE WHEN event_type = 'comment' THEN user_id END) as commenters
FROM analytics_events
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
  AND user_id IS NOT NULL;

-- ============================================================================
-- 完成
-- ============================================================================
