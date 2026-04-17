-- User Profiling System
-- Created: 2026-04-17
-- Description: 用户画像系统，包括用户画像表、行为分析和用户分群

-- ============================================================================
-- 1. 用户画像表
-- ============================================================================

-- 1.1 用户画像主表
CREATE TABLE IF NOT EXISTS user_profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

  -- 兴趣标签（基于浏览和互动内容）
  interests JSONB DEFAULT '[]',  -- [{"tag": "职场沟通", "score": 0.85}, ...]

  -- 活跃度指标
  activity_level VARCHAR(20) DEFAULT 'new',  -- 'new', 'active', 'inactive', 'churned'
  activity_score FLOAT DEFAULT 0,  -- 0-100 活跃度评分

  -- 偏好场景
  preferred_scenarios JSONB DEFAULT '[]',  -- [{"scenario": "职场", "frequency": 45}, ...]

  -- 参与度评分
  engagement_score FLOAT DEFAULT 0,  -- 0-100 参与度评分

  -- 内容偏好
  preferred_content_types JSONB DEFAULT '{}',  -- {"article": 0.6, "video": 0.3, "audio": 0.1}

  -- 行为统计
  total_views INT DEFAULT 0,
  total_favorites INT DEFAULT 0,
  total_shares INT DEFAULT 0,
  total_comments INT DEFAULT 0,
  total_searches INT DEFAULT 0,

  -- 时间统计
  avg_session_duration FLOAT DEFAULT 0,  -- 平均会话时长（秒）
  total_time_spent BIGINT DEFAULT 0,  -- 总使用时长（秒）
  last_active_at TIMESTAMPTZ,

  -- 用户分群
  user_segment VARCHAR(50),  -- 'power_user', 'casual_user', 'at_risk', 'new_user'
  segment_updated_at TIMESTAMPTZ,

  -- 元数据
  profile_version INT DEFAULT 1,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_user_profiles_activity_level ON user_profiles(activity_level);
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_segment ON user_profiles(user_segment);
CREATE INDEX IF NOT EXISTS idx_user_profiles_activity_score ON user_profiles(activity_score DESC);
CREATE INDEX IF NOT EXISTS idx_user_profiles_engagement_score ON user_profiles(engagement_score DESC);
CREATE INDEX IF NOT EXISTS idx_user_profiles_last_active ON user_profiles(last_active_at DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_user_profiles_interests ON user_profiles USING GIN(interests);
CREATE INDEX IF NOT EXISTS idx_user_profiles_scenarios ON user_profiles USING GIN(preferred_scenarios);

-- 注释
COMMENT ON TABLE user_profiles IS '用户画像表，存储用户兴趣、行为和分群信息';
COMMENT ON COLUMN user_profiles.interests IS '用户兴趣标签，JSON数组格式：[{"tag": "标签", "score": 0.85}]';
COMMENT ON COLUMN user_profiles.activity_level IS '活跃度等级：new(新用户), active(活跃), inactive(不活跃), churned(流失)';
COMMENT ON COLUMN user_profiles.user_segment IS '用户分群：power_user(重度用户), casual_user(轻度用户), at_risk(流失风险), new_user(新用户)';

-- ============================================================================
-- 2. 用户行为会话表
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  session_id UUID NOT NULL,

  -- 会话信息
  started_at TIMESTAMPTZ NOT NULL,
  ended_at TIMESTAMPTZ,
  duration INT,  -- 会话时长（秒）

  -- 会话统计
  page_views INT DEFAULT 0,
  content_views INT DEFAULT 0,
  searches INT DEFAULT 0,
  interactions INT DEFAULT 0,  -- 收藏、分享、评论等

  -- 设备信息
  device_type VARCHAR(50),  -- 'mobile', 'tablet', 'desktop'
  platform VARCHAR(50),  -- 'ios', 'android', 'web'

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_session_id ON user_sessions(session_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_started_at ON user_sessions(started_at DESC);

-- 注释
COMMENT ON TABLE user_sessions IS '用户会话表，记录每次用户访问的详细信息';

-- ============================================================================
-- 3. 用户兴趣演化表
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_interest_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,

  -- 兴趣快照
  interests JSONB NOT NULL,

  -- 变化信息
  change_type VARCHAR(20),  -- 'initial', 'update', 'major_shift'
  change_summary TEXT,  -- 变化描述

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_user_interest_history_user_id ON user_interest_history(user_id);
CREATE INDEX IF NOT EXISTS idx_user_interest_history_created_at ON user_interest_history(created_at DESC);

-- 注释
COMMENT ON TABLE user_interest_history IS '用户兴趣演化历史表，追踪用户兴趣变化';

-- ============================================================================
-- 4. 用户画像计算函数
-- ============================================================================

-- 4.1 计算用户兴趣标签
CREATE OR REPLACE FUNCTION compute_user_interests(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_interests JSONB;
BEGIN
  -- 基于最近30天的内容浏览和互动计算兴趣
  WITH content_interactions AS (
    SELECT
      ae.content_id,
      pc.tags,
      pc.scenario,
      CASE ae.event_type
        WHEN 'content_view' THEN 1
        WHEN 'favorite_add' THEN 3
        WHEN 'share' THEN 2
        WHEN 'comment' THEN 2
        ELSE 1
      END as weight
    FROM analytics_events ae
    LEFT JOIN published_content pc ON ae.content_id = pc.id
    WHERE ae.user_id = p_user_id
      AND ae.created_at >= NOW() - INTERVAL '30 days'
      AND ae.content_id IS NOT NULL
      AND pc.tags IS NOT NULL
  ),
  tag_scores AS (
    SELECT
      jsonb_array_elements_text(tags) as tag,
      SUM(weight) as total_weight
    FROM content_interactions
    GROUP BY tag
  ),
  normalized_scores AS (
    SELECT
      tag,
      total_weight::float / NULLIF((SELECT SUM(total_weight) FROM tag_scores), 0) as score
    FROM tag_scores
    WHERE total_weight > 0
    ORDER BY total_weight DESC
    LIMIT 20
  )
  SELECT jsonb_agg(
    jsonb_build_object(
      'tag', tag,
      'score', ROUND(score::numeric, 3)
    )
    ORDER BY score DESC
  )
  INTO v_interests
  FROM normalized_scores;

  RETURN COALESCE(v_interests, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- 4.2 计算活跃度等级
CREATE OR REPLACE FUNCTION compute_activity_level(p_user_id UUID)
RETURNS VARCHAR AS $$
DECLARE
  v_days_since_last_active INT;
  v_event_count_7d INT;
  v_event_count_30d INT;
BEGIN
  -- 获取最后活跃时间
  SELECT EXTRACT(DAY FROM NOW() - MAX(created_at))
  INTO v_days_since_last_active
  FROM analytics_events
  WHERE user_id = p_user_id;

  -- 获取最近7天和30天的事件数
  SELECT
    COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '7 days'),
    COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '30 days')
  INTO v_event_count_7d, v_event_count_30d
  FROM analytics_events
  WHERE user_id = p_user_id;

  -- 判断活跃度等级
  IF v_days_since_last_active IS NULL THEN
    RETURN 'new';
  ELSIF v_days_since_last_active > 30 THEN
    RETURN 'churned';
  ELSIF v_days_since_last_active > 7 THEN
    RETURN 'inactive';
  ELSIF v_event_count_7d >= 10 THEN
    RETURN 'active';
  ELSE
    RETURN 'inactive';
  END IF;
END;
$$ LANGUAGE plpgsql;

-- 4.3 计算活跃度评分
CREATE OR REPLACE FUNCTION compute_activity_score(p_user_id UUID)
RETURNS FLOAT AS $$
DECLARE
  v_score FLOAT := 0;
  v_days_active_30d INT;
  v_event_count_30d INT;
  v_avg_events_per_day FLOAT;
BEGIN
  -- 最近30天活跃天数
  SELECT COUNT(DISTINCT DATE(created_at))
  INTO v_days_active_30d
  FROM analytics_events
  WHERE user_id = p_user_id
    AND created_at >= NOW() - INTERVAL '30 days';

  -- 最近30天事件总数
  SELECT COUNT(*)
  INTO v_event_count_30d
  FROM analytics_events
  WHERE user_id = p_user_id
    AND created_at >= NOW() - INTERVAL '30 days';

  -- 计算评分
  v_avg_events_per_day := v_event_count_30d::float / NULLIF(v_days_active_30d, 0);

  -- 活跃天数得分（最高40分）
  v_score := v_score + LEAST(v_days_active_30d * 1.33, 40);

  -- 平均每天事件数得分（最高60分）
  v_score := v_score + LEAST(v_avg_events_per_day * 3, 60);

  RETURN LEAST(v_score, 100);
END;
$$ LANGUAGE plpgsql;

-- 4.4 计算偏好场景
CREATE OR REPLACE FUNCTION compute_preferred_scenarios(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_scenarios JSONB;
BEGIN
  WITH scenario_stats AS (
    SELECT
      pc.scenario,
      COUNT(*) as frequency
    FROM analytics_events ae
    LEFT JOIN published_content pc ON ae.content_id = pc.id
    WHERE ae.user_id = p_user_id
      AND ae.created_at >= NOW() - INTERVAL '30 days'
      AND ae.event_type IN ('content_view', 'favorite_add', 'share')
      AND pc.scenario IS NOT NULL
    GROUP BY pc.scenario
  )
  SELECT jsonb_agg(
    jsonb_build_object(
      'scenario', scenario,
      'frequency', frequency
    )
    ORDER BY frequency DESC
  )
  INTO v_scenarios
  FROM scenario_stats;

  RETURN COALESCE(v_scenarios, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- 4.5 计算参与度评分
CREATE OR REPLACE FUNCTION compute_engagement_score(p_user_id UUID)
RETURNS FLOAT AS $$
DECLARE
  v_score FLOAT := 0;
  v_view_count INT;
  v_favorite_count INT;
  v_share_count INT;
  v_comment_count INT;
BEGIN
  -- 统计最近30天的各类互动
  SELECT
    COUNT(*) FILTER (WHERE event_type = 'content_view'),
    COUNT(*) FILTER (WHERE event_type = 'favorite_add'),
    COUNT(*) FILTER (WHERE event_type = 'share'),
    COUNT(*) FILTER (WHERE event_type = 'comment')
  INTO v_view_count, v_favorite_count, v_share_count, v_comment_count
  FROM analytics_events
  WHERE user_id = p_user_id
    AND created_at >= NOW() - INTERVAL '30 days';

  -- 计算加权评分
  v_score := v_score + LEAST(v_view_count * 0.5, 30);  -- 浏览最高30分
  v_score := v_score + LEAST(v_favorite_count * 3, 30);  -- 收藏最高30分
  v_score := v_score + LEAST(v_share_count * 4, 20);  -- 分享最高20分
  v_score := v_score + LEAST(v_comment_count * 5, 20);  -- 评论最高20分

  RETURN LEAST(v_score, 100);
END;
$$ LANGUAGE plpgsql;

-- 4.6 计算用户分群
CREATE OR REPLACE FUNCTION compute_user_segment(p_user_id UUID)
RETURNS VARCHAR AS $$
DECLARE
  v_activity_score FLOAT;
  v_engagement_score FLOAT;
  v_days_since_signup INT;
  v_total_events INT;
BEGIN
  -- 获取活跃度和参与度评分
  v_activity_score := compute_activity_score(p_user_id);
  v_engagement_score := compute_engagement_score(p_user_id);

  -- 获取注册天数
  SELECT EXTRACT(DAY FROM NOW() - created_at)
  INTO v_days_since_signup
  FROM auth.users
  WHERE id = p_user_id;

  -- 获取总事件数
  SELECT COUNT(*)
  INTO v_total_events
  FROM analytics_events
  WHERE user_id = p_user_id;

  -- 分群逻辑
  IF v_days_since_signup <= 7 THEN
    RETURN 'new_user';
  ELSIF v_activity_score >= 70 AND v_engagement_score >= 60 THEN
    RETURN 'power_user';
  ELSIF v_activity_score < 30 OR v_engagement_score < 20 THEN
    RETURN 'at_risk';
  ELSE
    RETURN 'casual_user';
  END IF;
END;
$$ LANGUAGE plpgsql;

-- 4.7 更新用户画像（主函数）
CREATE OR REPLACE FUNCTION update_user_profile(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_profile JSONB;
  v_interests JSONB;
  v_activity_level VARCHAR;
  v_activity_score FLOAT;
  v_preferred_scenarios JSONB;
  v_engagement_score FLOAT;
  v_user_segment VARCHAR;
  v_stats RECORD;
BEGIN
  -- 计算各项指标
  v_interests := compute_user_interests(p_user_id);
  v_activity_level := compute_activity_level(p_user_id);
  v_activity_score := compute_activity_score(p_user_id);
  v_preferred_scenarios := compute_preferred_scenarios(p_user_id);
  v_engagement_score := compute_engagement_score(p_user_id);
  v_user_segment := compute_user_segment(p_user_id);

  -- 统计行为数据
  SELECT
    COUNT(*) FILTER (WHERE event_type = 'content_view') as total_views,
    COUNT(*) FILTER (WHERE event_type = 'favorite_add') as total_favorites,
    COUNT(*) FILTER (WHERE event_type = 'share') as total_shares,
    COUNT(*) FILTER (WHERE event_type = 'comment') as total_comments,
    COUNT(*) FILTER (WHERE event_type = 'search') as total_searches,
    MAX(created_at) as last_active_at
  INTO v_stats
  FROM analytics_events
  WHERE user_id = p_user_id;

  -- 更新或插入用户画像
  INSERT INTO user_profiles (
    user_id,
    interests,
    activity_level,
    activity_score,
    preferred_scenarios,
    engagement_score,
    user_segment,
    total_views,
    total_favorites,
    total_shares,
    total_comments,
    total_searches,
    last_active_at,
    segment_updated_at,
    updated_at
  ) VALUES (
    p_user_id,
    v_interests,
    v_activity_level,
    v_activity_score,
    v_preferred_scenarios,
    v_engagement_score,
    v_user_segment,
    COALESCE(v_stats.total_views, 0),
    COALESCE(v_stats.total_favorites, 0),
    COALESCE(v_stats.total_shares, 0),
    COALESCE(v_stats.total_comments, 0),
    COALESCE(v_stats.total_searches, 0),
    v_stats.last_active_at,
    NOW(),
    NOW()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    interests = EXCLUDED.interests,
    activity_level = EXCLUDED.activity_level,
    activity_score = EXCLUDED.activity_score,
    preferred_scenarios = EXCLUDED.preferred_scenarios,
    engagement_score = EXCLUDED.engagement_score,
    user_segment = EXCLUDED.user_segment,
    total_views = EXCLUDED.total_views,
    total_favorites = EXCLUDED.total_favorites,
    total_shares = EXCLUDED.total_shares,
    total_comments = EXCLUDED.total_comments,
    total_searches = EXCLUDED.total_searches,
    last_active_at = EXCLUDED.last_active_at,
    segment_updated_at = EXCLUDED.segment_updated_at,
    updated_at = NOW();

  -- 构建返回的画像数据
  v_profile := jsonb_build_object(
    'user_id', p_user_id,
    'interests', v_interests,
    'activity_level', v_activity_level,
    'activity_score', v_activity_score,
    'preferred_scenarios', v_preferred_scenarios,
    'engagement_score', v_engagement_score,
    'user_segment', v_user_segment,
    'stats', jsonb_build_object(
      'total_views', COALESCE(v_stats.total_views, 0),
      'total_favorites', COALESCE(v_stats.total_favorites, 0),
      'total_shares', COALESCE(v_stats.total_shares, 0),
      'total_comments', COALESCE(v_stats.total_comments, 0),
      'total_searches', COALESCE(v_stats.total_searches, 0)
    )
  );

  RETURN v_profile;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 5. 触发器：自动更新用户画像
-- ============================================================================

-- 5.1 创建触发器函数
CREATE OR REPLACE FUNCTION trigger_update_user_profile()
RETURNS TRIGGER AS $$
BEGIN
  -- 异步更新用户画像（避免阻塞事件插入）
  -- 实际生产环境建议使用队列或定时任务
  IF NEW.user_id IS NOT NULL THEN
    -- 这里只更新最后活跃时间，完整画像计算由定时任务处理
    UPDATE user_profiles
    SET last_active_at = NEW.created_at,
        updated_at = NOW()
    WHERE user_id = NEW.user_id;

    -- 如果用户画像不存在，创建初始画像
    IF NOT FOUND THEN
      INSERT INTO user_profiles (user_id, last_active_at)
      VALUES (NEW.user_id, NEW.created_at)
      ON CONFLICT (user_id) DO NOTHING;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5.2 创建触发器
DROP TRIGGER IF EXISTS trigger_update_user_profile ON analytics_events;
CREATE TRIGGER trigger_update_user_profile
AFTER INSERT ON analytics_events
FOR EACH ROW EXECUTE FUNCTION trigger_update_user_profile();

-- ============================================================================
-- 6. 用户分群视图
-- ============================================================================

-- 6.1 用户分群统计视图
CREATE OR REPLACE VIEW v_user_segment_stats AS
SELECT
  user_segment,
  COUNT(*) as user_count,
  AVG(activity_score) as avg_activity_score,
  AVG(engagement_score) as avg_engagement_score,
  AVG(total_views) as avg_views,
  AVG(total_favorites) as avg_favorites
FROM user_profiles
WHERE user_segment IS NOT NULL
GROUP BY user_segment;

-- 6.2 活跃用户视图
CREATE OR REPLACE VIEW v_active_users AS
SELECT
  up.user_id,
  u.email,
  up.activity_level,
  up.activity_score,
  up.engagement_score,
  up.user_segment,
  up.last_active_at,
  up.total_views,
  up.total_favorites,
  up.total_shares
FROM user_profiles up
LEFT JOIN auth.users u ON up.user_id = u.id
WHERE up.activity_level IN ('active')
ORDER BY up.activity_score DESC;

-- 6.3 流失风险用户视图
CREATE OR REPLACE VIEW v_at_risk_users AS
SELECT
  up.user_id,
  u.email,
  up.activity_level,
  up.activity_score,
  up.engagement_score,
  up.last_active_at,
  EXTRACT(DAY FROM NOW() - up.last_active_at) as days_inactive
FROM user_profiles up
LEFT JOIN auth.users u ON up.user_id = u.id
WHERE up.user_segment = 'at_risk'
   OR up.activity_level IN ('inactive', 'churned')
ORDER BY up.last_active_at ASC NULLS LAST;

-- ============================================================================
-- 7. RLS 策略
-- ============================================================================

-- 7.1 启用 RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_interest_history ENABLE ROW LEVEL SECURITY;

-- 7.2 用户可以查看自己的画像
CREATE POLICY "Users can view own profile"
ON user_profiles FOR SELECT
USING (auth.uid() = user_id);

-- 7.3 管理员可以查看所有画像
CREATE POLICY "Admins can view all profiles"
ON user_profiles FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_active = true
  )
);

-- 7.4 系统可以更新画像
CREATE POLICY "System can update profiles"
ON user_profiles FOR ALL
USING (true)
WITH CHECK (true);

-- ============================================================================
-- 8. 定时任务函数
-- ============================================================================

-- 8.1 批量更新用户画像
CREATE OR REPLACE FUNCTION batch_update_user_profiles(p_limit INT DEFAULT 100)
RETURNS TABLE(user_id UUID, success BOOLEAN, error TEXT) AS $$
DECLARE
  v_user RECORD;
BEGIN
  -- 选择需要更新的用户（最近活跃或画像过期）
  FOR v_user IN
    SELECT DISTINCT ae.user_id
    FROM analytics_events ae
    LEFT JOIN user_profiles up ON ae.user_id = up.user_id
    WHERE ae.user_id IS NOT NULL
      AND (
        up.updated_at IS NULL
        OR up.updated_at < NOW() - INTERVAL '1 day'
        OR ae.created_at > up.updated_at
      )
    ORDER BY ae.created_at DESC
    LIMIT p_limit
  LOOP
    BEGIN
      PERFORM update_user_profile(v_user.user_id);
      user_id := v_user.user_id;
      success := true;
      error := NULL;
      RETURN NEXT;
    EXCEPTION WHEN OTHERS THEN
      user_id := v_user.user_id;
      success := false;
      error := SQLERRM;
      RETURN NEXT;
    END;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 注释
COMMENT ON FUNCTION batch_update_user_profiles IS '批量更新用户画像，建议每小时执行一次';

-- ============================================================================
-- 完成
-- ============================================================================
