-- 用户画像相关视图和查询函数
-- Created: 2026-04-17
-- Description: 为管理后台和API提供便捷的查询视图和函数

-- ============================================================================
-- 1. 用户画像完整视图
-- ============================================================================

CREATE OR REPLACE VIEW v_user_profiles_complete AS
SELECT
  up.user_id,
  u.email,
  u.created_at as signup_date,
  EXTRACT(DAY FROM NOW() - u.created_at)::int as days_since_signup,

  -- 画像信息
  up.interests,
  up.activity_level,
  up.activity_score,
  up.preferred_scenarios,
  up.engagement_score,
  up.user_segment,

  -- 行为统计
  up.total_views,
  up.total_favorites,
  up.total_shares,
  up.total_comments,
  up.total_searches,

  -- 时间信息
  up.last_active_at,
  EXTRACT(DAY FROM NOW() - up.last_active_at)::int as days_since_active,
  up.updated_at as profile_updated_at,

  -- RFM 评分
  rfm.rfm_score,
  rfm.rfm_segment,
  rfm.recency_score,
  rfm.frequency_score,
  rfm.monetary_score

FROM user_profiles up
LEFT JOIN auth.users u ON up.user_id = u.id
LEFT JOIN user_rfm_scores rfm ON up.user_id = rfm.user_id;

-- ============================================================================
-- 2. 用户行为趋势视图
-- ============================================================================

CREATE OR REPLACE VIEW v_user_behavior_trends AS
SELECT
  user_id,
  DATE(created_at) as date,
  COUNT(*) as total_events,
  COUNT(*) FILTER (WHERE event_type = 'page_view') as page_views,
  COUNT(*) FILTER (WHERE event_type = 'content_view') as content_views,
  COUNT(*) FILTER (WHERE event_type = 'search') as searches,
  COUNT(*) FILTER (WHERE event_type = 'favorite_add') as favorites,
  COUNT(*) FILTER (WHERE event_type = 'share') as shares,
  COUNT(*) FILTER (WHERE event_type = 'comment') as comments
FROM analytics_events
WHERE user_id IS NOT NULL
  AND created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY user_id, DATE(created_at)
ORDER BY user_id, date DESC;

-- ============================================================================
-- 3. 用户兴趣分布视图
-- ============================================================================

CREATE OR REPLACE VIEW v_user_interest_distribution AS
WITH interest_tags AS (
  SELECT
    user_id,
    jsonb_array_elements(interests) as interest
  FROM user_profiles
  WHERE interests IS NOT NULL
    AND jsonb_array_length(interests) > 0
)
SELECT
  interest->>'tag' as tag,
  COUNT(DISTINCT user_id) as user_count,
  AVG((interest->>'score')::float) as avg_score,
  MIN((interest->>'score')::float) as min_score,
  MAX((interest->>'score')::float) as max_score
FROM interest_tags
GROUP BY interest->>'tag'
ORDER BY user_count DESC;

-- ============================================================================
-- 4. 场景偏好分布视图
-- ============================================================================

CREATE OR REPLACE VIEW v_scenario_preference_distribution AS
WITH scenario_prefs AS (
  SELECT
    user_id,
    jsonb_array_elements(preferred_scenarios) as scenario_data
  FROM user_profiles
  WHERE preferred_scenarios IS NOT NULL
    AND jsonb_array_length(preferred_scenarios) > 0
)
SELECT
  scenario_data->>'scenario' as scenario,
  COUNT(DISTINCT user_id) as user_count,
  AVG((scenario_data->>'frequency')::int) as avg_frequency,
  SUM((scenario_data->>'frequency')::int) as total_frequency
FROM scenario_prefs
GROUP BY scenario_data->>'scenario'
ORDER BY user_count DESC;

-- ============================================================================
-- 5. 用户留存分析视图
-- ============================================================================

CREATE OR REPLACE VIEW v_user_retention AS
WITH user_cohorts AS (
  SELECT
    user_id,
    DATE_TRUNC('week', created_at) as cohort_week
  FROM auth.users
),
user_activity AS (
  SELECT
    ae.user_id,
    DATE_TRUNC('week', ae.created_at) as activity_week
  FROM analytics_events ae
  WHERE ae.user_id IS NOT NULL
  GROUP BY ae.user_id, DATE_TRUNC('week', ae.created_at)
)
SELECT
  uc.cohort_week,
  COUNT(DISTINCT uc.user_id) as cohort_size,
  ua.activity_week,
  COUNT(DISTINCT ua.user_id) as active_users,
  ROUND(
    COUNT(DISTINCT ua.user_id)::numeric / NULLIF(COUNT(DISTINCT uc.user_id), 0) * 100,
    2
  ) as retention_rate
FROM user_cohorts uc
LEFT JOIN user_activity ua ON uc.user_id = ua.user_id
WHERE uc.cohort_week >= CURRENT_DATE - INTERVAL '12 weeks'
GROUP BY uc.cohort_week, ua.activity_week
ORDER BY uc.cohort_week DESC, ua.activity_week DESC;

-- ============================================================================
-- 6. 查询函数：获取用户完整画像
-- ============================================================================

CREATE OR REPLACE FUNCTION get_user_profile_detail(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'user_id', up.user_id,
    'email', u.email,
    'signup_date', u.created_at,
    'days_since_signup', EXTRACT(DAY FROM NOW() - u.created_at)::int,

    'profile', jsonb_build_object(
      'interests', up.interests,
      'activity_level', up.activity_level,
      'activity_score', up.activity_score,
      'preferred_scenarios', up.preferred_scenarios,
      'engagement_score', up.engagement_score,
      'user_segment', up.user_segment,
      'preferred_content_types', up.preferred_content_types
    ),

    'stats', jsonb_build_object(
      'total_views', up.total_views,
      'total_favorites', up.total_favorites,
      'total_shares', up.total_shares,
      'total_comments', up.total_comments,
      'total_searches', up.total_searches,
      'last_active_at', up.last_active_at,
      'days_since_active', EXTRACT(DAY FROM NOW() - up.last_active_at)::int
    ),

    'rfm', jsonb_build_object(
      'rfm_score', rfm.rfm_score,
      'rfm_segment', rfm.rfm_segment,
      'recency_score', rfm.recency_score,
      'frequency_score', rfm.frequency_score,
      'monetary_score', rfm.monetary_score,
      'recency_days', rfm.recency_days,
      'frequency_count', rfm.frequency_count,
      'monetary_value', rfm.monetary_value
    ),

    'recent_activity', (
      SELECT jsonb_agg(
        jsonb_build_object(
          'event_type', event_type,
          'created_at', created_at,
          'content_id', content_id
        )
        ORDER BY created_at DESC
      )
      FROM (
        SELECT event_type, created_at, content_id
        FROM analytics_events
        WHERE user_id = p_user_id
        ORDER BY created_at DESC
        LIMIT 20
      ) recent
    )
  )
  INTO v_result
  FROM user_profiles up
  LEFT JOIN auth.users u ON up.user_id = u.id
  LEFT JOIN user_rfm_scores rfm ON up.user_id = rfm.user_id
  WHERE up.user_id = p_user_id;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 7. 查询函数：获取相似用户
-- ============================================================================

CREATE OR REPLACE FUNCTION get_similar_users(
  p_user_id UUID,
  p_limit INT DEFAULT 10
)
RETURNS TABLE(
  user_id UUID,
  email TEXT,
  similarity_score FLOAT,
  common_interests JSONB,
  common_scenarios JSONB
) AS $$
DECLARE
  v_user_interests JSONB;
  v_user_scenarios JSONB;
BEGIN
  -- 获取目标用户的兴趣和场景
  SELECT interests, preferred_scenarios
  INTO v_user_interests, v_user_scenarios
  FROM user_profiles
  WHERE user_profiles.user_id = p_user_id;

  IF v_user_interests IS NULL THEN
    RETURN;
  END IF;

  -- 查找相似用户
  RETURN QUERY
  WITH target_tags AS (
    SELECT jsonb_array_elements_text(v_user_interests) as tag
  ),
  target_scenarios AS (
    SELECT jsonb_array_elements_text(v_user_scenarios) as scenario
  ),
  similar_users AS (
    SELECT
      up.user_id,
      u.email,
      -- 计算相似度（基于共同兴趣和场景）
      (
        -- 共同兴趣标签数量
        (SELECT COUNT(*)
         FROM target_tags tt
         WHERE up.interests::text LIKE '%' || tt.tag || '%') * 10 +
        -- 共同偏好场景数量
        (SELECT COUNT(*)
         FROM target_scenarios ts
         WHERE up.preferred_scenarios::text LIKE '%' || ts.scenario || '%') * 5
      )::float as similarity_score,
      -- 共同兴趣
      (SELECT jsonb_agg(DISTINCT tt.tag)
       FROM target_tags tt
       WHERE up.interests::text LIKE '%' || tt.tag || '%') as common_interests,
      -- 共同场景
      (SELECT jsonb_agg(DISTINCT ts.scenario)
       FROM target_scenarios ts
       WHERE up.preferred_scenarios::text LIKE '%' || ts.scenario || '%') as common_scenarios
    FROM user_profiles up
    LEFT JOIN auth.users u ON up.user_id = u.id
    WHERE up.user_id != p_user_id
      AND up.interests IS NOT NULL
  )
  SELECT
    su.user_id,
    su.email,
    su.similarity_score,
    su.common_interests,
    su.common_scenarios
  FROM similar_users su
  WHERE su.similarity_score > 0
  ORDER BY su.similarity_score DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 8. 查询函数：获取用户行为时间线
-- ============================================================================

CREATE OR REPLACE FUNCTION get_user_timeline(
  p_user_id UUID,
  p_days INT DEFAULT 30,
  p_limit INT DEFAULT 100
)
RETURNS TABLE(
  event_id UUID,
  event_type VARCHAR,
  event_time TIMESTAMPTZ,
  content_id UUID,
  content_title TEXT,
  properties JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ae.id,
    ae.event_type,
    ae.created_at,
    ae.content_id,
    pc.title,
    ae.properties
  FROM analytics_events ae
  LEFT JOIN published_content pc ON ae.content_id = pc.id
  WHERE ae.user_id = p_user_id
    AND ae.created_at >= NOW() - (p_days || ' days')::interval
  ORDER BY ae.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 9. 查询函数：获取用户内容偏好
-- ============================================================================

CREATE OR REPLACE FUNCTION get_user_content_preferences(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  WITH content_stats AS (
    SELECT
      pc.content_type,
      COUNT(*) as view_count,
      COUNT(*) FILTER (WHERE ae.event_type = 'favorite_add') as favorite_count,
      COUNT(*) FILTER (WHERE ae.event_type = 'share') as share_count
    FROM analytics_events ae
    LEFT JOIN published_content pc ON ae.content_id = pc.id
    WHERE ae.user_id = p_user_id
      AND ae.created_at >= NOW() - INTERVAL '30 days'
      AND pc.content_type IS NOT NULL
    GROUP BY pc.content_type
  ),
  total_views AS (
    SELECT SUM(view_count) as total FROM content_stats
  )
  SELECT jsonb_object_agg(
    content_type,
    jsonb_build_object(
      'view_count', view_count,
      'favorite_count', favorite_count,
      'share_count', share_count,
      'preference_score', ROUND((view_count::numeric / NULLIF(tv.total, 0))::numeric, 3)
    )
  )
  INTO v_result
  FROM content_stats cs, total_views tv;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 10. 管理后台统计视图
-- ============================================================================

CREATE OR REPLACE VIEW v_admin_user_profile_stats AS
SELECT
  COUNT(*) as total_users,
  COUNT(*) FILTER (WHERE activity_level = 'active') as active_users,
  COUNT(*) FILTER (WHERE activity_level = 'inactive') as inactive_users,
  COUNT(*) FILTER (WHERE activity_level = 'churned') as churned_users,
  COUNT(*) FILTER (WHERE user_segment = 'power_user') as power_users,
  COUNT(*) FILTER (WHERE user_segment = 'at_risk') as at_risk_users,
  AVG(activity_score) as avg_activity_score,
  AVG(engagement_score) as avg_engagement_score,
  AVG(total_views) as avg_views_per_user,
  AVG(total_favorites) as avg_favorites_per_user
FROM user_profiles;

-- ============================================================================
-- 11. RLS 策略
-- ============================================================================

-- 用户可以查看自己的推荐
CREATE OR REPLACE FUNCTION user_can_view_recommendations(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN auth.uid() = p_user_id OR EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_active = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 完成
-- ============================================================================
