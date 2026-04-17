-- 用户分群功能
-- Created: 2026-04-17
-- Description: 实现用户分群、RFM分析和个性化推荐

-- ============================================================================
-- 1. 用户分群配置表
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_segment_configs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  segment_name VARCHAR(50) UNIQUE NOT NULL,
  display_name VARCHAR(100) NOT NULL,
  description TEXT,

  -- 分群规则（JSON格式）
  rules JSONB NOT NULL,

  -- 优先级（数字越小优先级越高）
  priority INT DEFAULT 100,

  -- 是否启用
  is_active BOOLEAN DEFAULT true,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 插入默认分群配置
INSERT INTO user_segment_configs (segment_name, display_name, description, rules, priority) VALUES
  ('power_user', '重度用户', '高活跃度、高参与度的核心用户',
   '{"activity_score": {"min": 70}, "engagement_score": {"min": 60}}'::jsonb, 10),
  ('active_user', '活跃用户', '定期使用产品的用户',
   '{"activity_level": ["active"], "activity_score": {"min": 40}}'::jsonb, 20),
  ('casual_user', '轻度用户', '偶尔使用产品的用户',
   '{"activity_score": {"min": 20, "max": 70}}'::jsonb, 30),
  ('at_risk', '流失风险用户', '活跃度下降，有流失风险',
   '{"activity_score": {"max": 30}, "days_since_signup": {"min": 7}}'::jsonb, 40),
  ('new_user', '新用户', '刚注册的新用户',
   '{"days_since_signup": {"max": 7}}'::jsonb, 50),
  ('churned', '流失用户', '长期未活跃的用户',
   '{"activity_level": ["churned"], "days_inactive": {"min": 30}}'::jsonb, 60)
ON CONFLICT (segment_name) DO NOTHING;

-- 索引
CREATE INDEX IF NOT EXISTS idx_user_segment_configs_priority ON user_segment_configs(priority);

-- ============================================================================
-- 2. RFM 分析表
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_rfm_scores (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Recency（最近一次活跃）
  recency_days INT,  -- 距离最后活跃的天数
  recency_score INT CHECK (recency_score BETWEEN 1 AND 5),

  -- Frequency（活跃频率）
  frequency_count INT,  -- 30天内的活跃天数
  frequency_score INT CHECK (frequency_score BETWEEN 1 AND 5),

  -- Monetary（价值贡献）
  monetary_value FLOAT,  -- 综合价值评分
  monetary_score INT CHECK (monetary_score BETWEEN 1 AND 5),

  -- RFM 总分
  rfm_score VARCHAR(3),  -- 例如 "555" 表示最高价值用户
  rfm_segment VARCHAR(50),  -- 'champions', 'loyal', 'at_risk', 'lost'

  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_user_rfm_scores_rfm_score ON user_rfm_scores(rfm_score DESC);
CREATE INDEX IF NOT EXISTS idx_user_rfm_scores_rfm_segment ON user_rfm_scores(rfm_segment);

-- 注释
COMMENT ON TABLE user_rfm_scores IS 'RFM分析表，用于用户价值分层';
COMMENT ON COLUMN user_rfm_scores.rfm_segment IS 'RFM分群：champions(冠军), loyal(忠诚), potential(潜力), at_risk(流失风险), lost(流失)';

-- ============================================================================
-- 3. RFM 计算函数
-- ============================================================================

-- 3.1 计算 RFM 评分
CREATE OR REPLACE FUNCTION calculate_rfm_scores(p_user_id UUID)
RETURNS void AS $$
DECLARE
  v_recency_days INT;
  v_frequency_count INT;
  v_monetary_value FLOAT;
  v_recency_score INT;
  v_frequency_score INT;
  v_monetary_score INT;
  v_rfm_score VARCHAR(3);
  v_rfm_segment VARCHAR(50);
BEGIN
  -- 计算 Recency（最近活跃天数）
  SELECT EXTRACT(DAY FROM NOW() - MAX(created_at))::int
  INTO v_recency_days
  FROM analytics_events
  WHERE user_id = p_user_id;

  -- 计算 Frequency（30天内活跃天数）
  SELECT COUNT(DISTINCT DATE(created_at))
  INTO v_frequency_count
  FROM analytics_events
  WHERE user_id = p_user_id
    AND created_at >= NOW() - INTERVAL '30 days';

  -- 计算 Monetary（综合价值：互动权重）
  SELECT
    COUNT(*) FILTER (WHERE event_type = 'content_view') * 1 +
    COUNT(*) FILTER (WHERE event_type = 'favorite_add') * 3 +
    COUNT(*) FILTER (WHERE event_type = 'share') * 5 +
    COUNT(*) FILTER (WHERE event_type = 'comment') * 4
  INTO v_monetary_value
  FROM analytics_events
  WHERE user_id = p_user_id
    AND created_at >= NOW() - INTERVAL '30 days';

  -- 计算 Recency Score (1-5, 越小越好)
  v_recency_score := CASE
    WHEN v_recency_days IS NULL THEN 1
    WHEN v_recency_days <= 1 THEN 5
    WHEN v_recency_days <= 3 THEN 4
    WHEN v_recency_days <= 7 THEN 3
    WHEN v_recency_days <= 14 THEN 2
    ELSE 1
  END;

  -- 计算 Frequency Score (1-5, 越大越好)
  v_frequency_score := CASE
    WHEN v_frequency_count >= 20 THEN 5
    WHEN v_frequency_count >= 10 THEN 4
    WHEN v_frequency_count >= 5 THEN 3
    WHEN v_frequency_count >= 2 THEN 2
    ELSE 1
  END;

  -- 计算 Monetary Score (1-5, 越大越好)
  v_monetary_score := CASE
    WHEN v_monetary_value >= 100 THEN 5
    WHEN v_monetary_value >= 50 THEN 4
    WHEN v_monetary_value >= 20 THEN 3
    WHEN v_monetary_value >= 5 THEN 2
    ELSE 1
  END;

  -- 组合 RFM Score
  v_rfm_score := v_recency_score::text || v_frequency_score::text || v_monetary_score::text;

  -- 确定 RFM Segment
  v_rfm_segment := CASE
    WHEN v_recency_score >= 4 AND v_frequency_score >= 4 AND v_monetary_score >= 4 THEN 'champions'
    WHEN v_recency_score >= 3 AND v_frequency_score >= 3 AND v_monetary_score >= 3 THEN 'loyal'
    WHEN v_recency_score >= 4 AND v_frequency_score <= 2 THEN 'potential'
    WHEN v_recency_score <= 2 AND v_frequency_score >= 3 THEN 'at_risk'
    WHEN v_recency_score <= 2 AND v_frequency_score <= 2 THEN 'lost'
    ELSE 'casual'
  END;

  -- 保存 RFM 评分
  INSERT INTO user_rfm_scores (
    user_id,
    recency_days,
    recency_score,
    frequency_count,
    frequency_score,
    monetary_value,
    monetary_score,
    rfm_score,
    rfm_segment,
    updated_at
  ) VALUES (
    p_user_id,
    v_recency_days,
    v_recency_score,
    v_frequency_count,
    v_frequency_score,
    v_monetary_value,
    v_monetary_score,
    v_rfm_score,
    v_rfm_segment,
    NOW()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    recency_days = EXCLUDED.recency_days,
    recency_score = EXCLUDED.recency_score,
    frequency_count = EXCLUDED.frequency_count,
    frequency_score = EXCLUDED.frequency_score,
    monetary_value = EXCLUDED.monetary_value,
    monetary_score = EXCLUDED.monetary_score,
    rfm_score = EXCLUDED.rfm_score,
    rfm_segment = EXCLUDED.rfm_segment,
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 4. 个性化推荐函数
-- ============================================================================

-- 4.1 基于用户画像的内容推荐
CREATE OR REPLACE FUNCTION get_personalized_recommendations(
  p_user_id UUID,
  p_limit INT DEFAULT 10
)
RETURNS TABLE(
  content_id UUID,
  title TEXT,
  content_type VARCHAR,
  scenario VARCHAR,
  relevance_score FLOAT,
  reason TEXT
) AS $$
DECLARE
  v_user_interests JSONB;
  v_preferred_scenarios JSONB;
BEGIN
  -- 获取用户画像
  SELECT interests, preferred_scenarios
  INTO v_user_interests, v_preferred_scenarios
  FROM user_profiles
  WHERE user_id = p_user_id;

  -- 如果用户画像不存在，返回热门内容
  IF v_user_interests IS NULL THEN
    RETURN QUERY
    SELECT
      pc.id,
      pc.title,
      pc.content_type,
      pc.scenario,
      ac.view_count::float / NULLIF((SELECT MAX(view_count) FROM analytics_content), 0) as relevance_score,
      '热门内容' as reason
    FROM published_content pc
    LEFT JOIN analytics_content ac ON pc.id = ac.content_id
    WHERE pc.status = 'published'
    ORDER BY ac.view_count DESC NULLS LAST
    LIMIT p_limit;
    RETURN;
  END IF;

  -- 基于兴趣标签和场景的个性化推荐
  RETURN QUERY
  WITH user_tags AS (
    SELECT jsonb_array_elements_text(v_user_interests) as interest_tag
  ),
  user_scenarios AS (
    SELECT
      elem->>'scenario' as scenario,
      (elem->>'frequency')::int as frequency
    FROM jsonb_array_elements(v_preferred_scenarios) elem
  ),
  scored_content AS (
    SELECT
      pc.id,
      pc.title,
      pc.content_type,
      pc.scenario,
      -- 计算相关性评分
      (
        -- 标签匹配度（0-50分）
        COALESCE(
          (SELECT COUNT(*) * 10
           FROM user_tags ut
           WHERE pc.tags ? ut.interest_tag),
          0
        ) +
        -- 场景匹配度（0-30分）
        COALESCE(
          (SELECT us.frequency * 0.5
           FROM user_scenarios us
           WHERE us.scenario = pc.scenario),
          0
        ) +
        -- 内容热度（0-20分）
        COALESCE(
          ac.view_count::float / NULLIF((SELECT MAX(view_count) FROM analytics_content), 0) * 20,
          0
        )
      ) as relevance_score,
      CASE
        WHEN EXISTS (SELECT 1 FROM user_tags ut WHERE pc.tags ? ut.interest_tag) THEN '基于您的兴趣'
        WHEN EXISTS (SELECT 1 FROM user_scenarios us WHERE us.scenario = pc.scenario) THEN '基于您的偏好场景'
        ELSE '热门推荐'
      END as reason
    FROM published_content pc
    LEFT JOIN analytics_content ac ON pc.id = ac.content_id
    WHERE pc.status = 'published'
      -- 排除已查看的内容
      AND NOT EXISTS (
        SELECT 1 FROM analytics_events ae
        WHERE ae.user_id = p_user_id
          AND ae.content_id = pc.id
          AND ae.event_type = 'content_view'
          AND ae.created_at >= NOW() - INTERVAL '7 days'
      )
  )
  SELECT
    sc.id,
    sc.title,
    sc.content_type,
    sc.scenario,
    sc.relevance_score,
    sc.reason
  FROM scored_content sc
  WHERE sc.relevance_score > 0
  ORDER BY sc.relevance_score DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 5. 用户分群视图
-- ============================================================================

-- 5.1 用户分群详情视图
CREATE OR REPLACE VIEW v_user_segments_detail AS
SELECT
  up.user_segment,
  COUNT(*) as user_count,
  AVG(up.activity_score) as avg_activity_score,
  AVG(up.engagement_score) as avg_engagement_score,
  AVG(up.total_views) as avg_views,
  AVG(up.total_favorites) as avg_favorites,
  AVG(up.total_shares) as avg_shares,
  AVG(up.total_comments) as avg_comments,
  AVG(EXTRACT(DAY FROM NOW() - up.last_active_at)) as avg_days_since_active
FROM user_profiles up
WHERE up.user_segment IS NOT NULL
GROUP BY up.user_segment
ORDER BY user_count DESC;

-- 5.2 RFM 分群统计视图
CREATE OR REPLACE VIEW v_rfm_segment_stats AS
SELECT
  rfm_segment,
  COUNT(*) as user_count,
  AVG(recency_score) as avg_recency_score,
  AVG(frequency_score) as avg_frequency_score,
  AVG(monetary_score) as avg_monetary_score,
  AVG(monetary_value) as avg_monetary_value
FROM user_rfm_scores
GROUP BY rfm_segment
ORDER BY user_count DESC;

-- ============================================================================
-- 6. RLS 策略
-- ============================================================================

ALTER TABLE user_segment_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_rfm_scores ENABLE ROW LEVEL SECURITY;

-- 管理员可以查看分群配置
CREATE POLICY "Admins can view segment configs"
ON user_segment_configs FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_active = true
  )
);

-- 用户可以查看自己的 RFM 评分
CREATE POLICY "Users can view own RFM scores"
ON user_rfm_scores FOR SELECT
USING (auth.uid() = user_id);

-- 管理员可以查看所有 RFM 评分
CREATE POLICY "Admins can view all RFM scores"
ON user_rfm_scores FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_active = true
  )
);

-- ============================================================================
-- 完成
-- ============================================================================
