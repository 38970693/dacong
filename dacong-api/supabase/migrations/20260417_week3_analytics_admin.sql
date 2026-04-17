-- Week 3: Analytics and Admin Tables
-- Created: 2026-04-17
-- Description: 创建数据分析和运营后台所需的数据库表

-- ============================================================================
-- 1. 数据分析表
-- ============================================================================

-- 1.1 原始事件表
CREATE TABLE IF NOT EXISTS analytics_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_type VARCHAR(50) NOT NULL,
  user_id UUID REFERENCES auth.users(id),  -- 可为空（匿名用户）
  session_id UUID NOT NULL,
  content_id UUID,  -- 可为空（非内容事件）
  properties JSONB DEFAULT '{}',  -- 事件属性
  device_info JSONB DEFAULT '{}',  -- 设备信息
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引优化
CREATE INDEX IF NOT EXISTS idx_analytics_events_type ON analytics_events(event_type);
CREATE INDEX IF NOT EXISTS idx_analytics_events_user ON analytics_events(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_analytics_events_content ON analytics_events(content_id) WHERE content_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_analytics_events_created_at ON analytics_events(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_events_type_created ON analytics_events(event_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_events_session ON analytics_events(session_id);

-- 注释
COMMENT ON TABLE analytics_events IS '原始事件表，存储所有用户行为事件';
COMMENT ON COLUMN analytics_events.event_type IS '事件类型：page_view, content_view, search等';
COMMENT ON COLUMN analytics_events.properties IS '事件属性，JSON格式存储灵活数据';
COMMENT ON COLUMN analytics_events.device_info IS '设备信息：platform, os, browser等';

-- ============================================================================

-- 1.2 每日汇总表
CREATE TABLE IF NOT EXISTS analytics_daily (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  date DATE NOT NULL,
  metric_type VARCHAR(50) NOT NULL,  -- 'dau', 'pv', 'content_view'等
  metric_value BIGINT NOT NULL,
  dimensions JSONB DEFAULT '{}',  -- 维度信息（场景、内容类型等）
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(date, metric_type, dimensions)
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_analytics_daily_date ON analytics_daily(date DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_daily_type ON analytics_daily(metric_type);
CREATE INDEX IF NOT EXISTS idx_analytics_daily_date_type ON analytics_daily(date DESC, metric_type);

-- 注释
COMMENT ON TABLE analytics_daily IS '每日汇总表，存储预计算的指标';
COMMENT ON COLUMN analytics_daily.metric_type IS '指标类型：dau, mau, pv, content_view等';
COMMENT ON COLUMN analytics_daily.dimensions IS '维度信息，用于多维度分析';

-- ============================================================================

-- 1.3 内容统计表
CREATE TABLE IF NOT EXISTS analytics_content (
  content_id UUID PRIMARY KEY,
  view_count BIGINT DEFAULT 0,
  unique_view_count BIGINT DEFAULT 0,
  favorite_count BIGINT DEFAULT 0,
  share_count BIGINT DEFAULT 0,
  helpful_count BIGINT DEFAULT 0,
  unhelpful_count BIGINT DEFAULT 0,
  avg_read_time FLOAT DEFAULT 0,  -- 平均阅读时长（秒）
  last_viewed_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_analytics_content_view_count ON analytics_content(view_count DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_content_helpful_rate ON analytics_content(
  (helpful_count::float / NULLIF(helpful_count + unhelpful_count, 0)) DESC NULLS LAST
);
CREATE INDEX IF NOT EXISTS idx_analytics_content_last_viewed ON analytics_content(last_viewed_at DESC NULLS LAST);

-- 注释
COMMENT ON TABLE analytics_content IS '内容统计表，实时更新内容相关指标';
COMMENT ON COLUMN analytics_content.avg_read_time IS '平均阅读时长，单位：秒';

-- ============================================================================

-- 1.4 触发器：自动更新内容统计
CREATE OR REPLACE FUNCTION update_content_stats()
RETURNS TRIGGER AS $$
BEGIN
  -- 内容查看事件
  IF NEW.event_type = 'content_view' AND NEW.content_id IS NOT NULL THEN
    INSERT INTO analytics_content (content_id, view_count, unique_view_count, last_viewed_at)
    VALUES (NEW.content_id, 1, 1, NEW.created_at)
    ON CONFLICT (content_id) DO UPDATE SET
      view_count = analytics_content.view_count + 1,
      last_viewed_at = NEW.created_at,
      updated_at = NOW();
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

-- 创建触发器
DROP TRIGGER IF EXISTS trigger_update_content_stats ON analytics_events;
CREATE TRIGGER trigger_update_content_stats
AFTER INSERT ON analytics_events
FOR EACH ROW EXECUTE FUNCTION update_content_stats();

-- ============================================================================
-- 2. 运营后台表
-- ============================================================================

-- 2.1 管理员用户表
CREATE TABLE IF NOT EXISTS admin_users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) UNIQUE,
  email VARCHAR(255) UNIQUE NOT NULL,
  role VARCHAR(50) NOT NULL DEFAULT 'content_admin',
  permissions JSONB DEFAULT '{}',
  is_active BOOLEAN DEFAULT true,
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_admin_users_user_id ON admin_users(user_id);
CREATE INDEX IF NOT EXISTS idx_admin_users_role ON admin_users(role);
CREATE INDEX IF NOT EXISTS idx_admin_users_email ON admin_users(email);

-- 注释
COMMENT ON TABLE admin_users IS '管理员用户表';
COMMENT ON COLUMN admin_users.role IS '角色：super_admin, content_admin, user_admin';
COMMENT ON COLUMN admin_users.permissions IS '细粒度权限配置';

-- ============================================================================

-- 2.2 审核记录表
CREATE TABLE IF NOT EXISTS review_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  content_id UUID,  -- 关联generated_content或published_content
  admin_id UUID REFERENCES admin_users(id),
  action VARCHAR(50) NOT NULL,  -- 'approve', 'reject', 'edit', 'delete'
  reason TEXT,  -- 拒绝原因或修改说明
  before_data JSONB,  -- 修改前数据
  after_data JSONB,  -- 修改后数据
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_review_logs_content ON review_logs(content_id);
CREATE INDEX IF NOT EXISTS idx_review_logs_admin ON review_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_review_logs_created_at ON review_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_review_logs_action ON review_logs(action);

-- 注释
COMMENT ON TABLE review_logs IS '审核记录表，记录所有审核操作';
COMMENT ON COLUMN review_logs.action IS '操作类型：approve, reject, edit, delete';

-- ============================================================================

-- 2.3 操作日志表
CREATE TABLE IF NOT EXISTS admin_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id UUID REFERENCES admin_users(id),
  action VARCHAR(100) NOT NULL,  -- 'login', 'ban_user', 'edit_content'等
  resource_type VARCHAR(50),  -- 'user', 'content', 'settings'
  resource_id UUID,
  details JSONB DEFAULT '{}',
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_admin_logs_admin ON admin_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_logs_action ON admin_logs(action);
CREATE INDEX IF NOT EXISTS idx_admin_logs_created_at ON admin_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_logs_resource ON admin_logs(resource_type, resource_id);

-- 注释
COMMENT ON TABLE admin_logs IS '操作日志表，记录所有管理员操作';
COMMENT ON COLUMN admin_logs.action IS '操作类型：login, logout, ban_user, edit_content等';

-- ============================================================================
-- 3. Row Level Security (RLS) 策略
-- ============================================================================

-- 3.1 启用RLS
ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics_daily ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE review_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_logs ENABLE ROW LEVEL SECURITY;

-- 3.2 分析表策略：只有管理员可以查看
CREATE POLICY "Admins can view analytics_events"
ON analytics_events FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_active = true
  )
);

CREATE POLICY "Admins can view analytics_daily"
ON analytics_daily FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_active = true
  )
);

CREATE POLICY "Admins can view analytics_content"
ON analytics_content FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_active = true
  )
);

-- 3.3 管理员表策略
CREATE POLICY "Admins can view admin_users"
ON admin_users FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_active = true
  )
);

CREATE POLICY "Super admins can manage admin_users"
ON admin_users FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND role = 'super_admin' AND is_active = true
  )
);

-- 3.4 审核记录策略
CREATE POLICY "Admins can view review_logs"
ON review_logs FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_active = true
  )
);

CREATE POLICY "Admins can insert review_logs"
ON review_logs FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_active = true
  )
);

-- 3.5 操作日志策略
CREATE POLICY "Admins can view admin_logs"
ON admin_logs FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_active = true
  )
);

CREATE POLICY "System can insert admin_logs"
ON admin_logs FOR INSERT
WITH CHECK (true);  -- 允许系统自动记录

-- ============================================================================
-- 4. 常用视图
-- ============================================================================

-- 4.1 今日统计视图
CREATE OR REPLACE VIEW v_today_stats AS
SELECT
  (SELECT COUNT(DISTINCT user_id) FROM analytics_events
   WHERE created_at >= CURRENT_DATE AND user_id IS NOT NULL) as dau,
  (SELECT COUNT(*) FROM analytics_events
   WHERE created_at >= CURRENT_DATE AND event_type = 'page_view') as pv,
  (SELECT COUNT(DISTINCT user_id) FROM auth.users
   WHERE created_at >= CURRENT_DATE) as new_users,
  (SELECT COUNT(*) FROM published_content
   WHERE published_at >= CURRENT_DATE) as published_content;

-- 4.2 内容热度排行视图
CREATE OR REPLACE VIEW v_content_ranking AS
SELECT
  ac.content_id,
  pc.title,
  pc.content_type,
  ac.view_count,
  ac.favorite_count,
  ac.share_count,
  ac.helpful_count,
  ac.unhelpful_count,
  CASE
    WHEN (ac.helpful_count + ac.unhelpful_count) > 0
    THEN ac.helpful_count::float / (ac.helpful_count + ac.unhelpful_count)
    ELSE NULL
  END as helpful_rate,
  ac.last_viewed_at
FROM analytics_content ac
LEFT JOIN published_content pc ON ac.content_id = pc.id
ORDER BY ac.view_count DESC;

-- 4.3 审核队列视图
CREATE OR REPLACE VIEW v_review_queue AS
SELECT
  gc.id,
  gc.content_type,
  gc.title,
  gc.ai_confidence,
  gc.quality_score,
  gc.created_at,
  CASE
    WHEN gc.ai_confidence < 0.75 THEN 'high'
    WHEN gc.ai_confidence < 0.85 THEN 'medium'
    ELSE 'low'
  END as priority
FROM generated_content gc
WHERE gc.status = 'pending'
ORDER BY
  CASE
    WHEN gc.ai_confidence < 0.75 THEN 1
    WHEN gc.ai_confidence < 0.85 THEN 2
    ELSE 3
  END,
  gc.created_at ASC;

-- ============================================================================
-- 5. 初始化数据
-- ============================================================================

-- 5.1 创建默认超级管理员（需要手动修改email）
-- INSERT INTO admin_users (email, role, permissions)
-- VALUES (
--   'admin@dacong.ai',
--   'super_admin',
--   '{"content": ["review", "edit", "publish", "delete"], "user": ["view", "ban"], "analytics": ["view"], "settings": ["view", "edit"]}'
-- )
-- ON CONFLICT (email) DO NOTHING;

-- ============================================================================
-- 6. 定时任务函数（需要配合pg_cron或外部调度器）
-- ============================================================================

-- 6.1 每日汇总函数
CREATE OR REPLACE FUNCTION calculate_daily_metrics(target_date DATE DEFAULT CURRENT_DATE - 1)
RETURNS void AS $$
BEGIN
  -- 计算DAU
  INSERT INTO analytics_daily (date, metric_type, metric_value)
  SELECT
    target_date,
    'dau',
    COUNT(DISTINCT user_id)
  FROM analytics_events
  WHERE created_at >= target_date
    AND created_at < target_date + 1
    AND user_id IS NOT NULL
  ON CONFLICT (date, metric_type, dimensions) DO UPDATE
  SET metric_value = EXCLUDED.metric_value;

  -- 计算PV
  INSERT INTO analytics_daily (date, metric_type, metric_value)
  SELECT
    target_date,
    'pv',
    COUNT(*)
  FROM analytics_events
  WHERE created_at >= target_date
    AND created_at < target_date + 1
    AND event_type = 'page_view'
  ON CONFLICT (date, metric_type, dimensions) DO UPDATE
  SET metric_value = EXCLUDED.metric_value;

  -- 计算内容查看量
  INSERT INTO analytics_daily (date, metric_type, metric_value)
  SELECT
    target_date,
    'content_view',
    COUNT(*)
  FROM analytics_events
  WHERE created_at >= target_date
    AND created_at < target_date + 1
    AND event_type = 'content_view'
  ON CONFLICT (date, metric_type, dimensions) DO UPDATE
  SET metric_value = EXCLUDED.metric_value;

  -- 按场景统计
  INSERT INTO analytics_daily (date, metric_type, metric_value, dimensions)
  SELECT
    target_date,
    'content_view_by_scenario',
    COUNT(*),
    jsonb_build_object('scenario', properties->>'scenario')
  FROM analytics_events
  WHERE created_at >= target_date
    AND created_at < target_date + 1
    AND event_type = 'content_view'
    AND properties->>'scenario' IS NOT NULL
  GROUP BY properties->>'scenario'
  ON CONFLICT (date, metric_type, dimensions) DO UPDATE
  SET metric_value = EXCLUDED.metric_value;
END;
$$ LANGUAGE plpgsql;

-- 注释
COMMENT ON FUNCTION calculate_daily_metrics IS '计算每日汇总指标，建议每天凌晨1点执行';

-- ============================================================================
-- 完成
-- ============================================================================
