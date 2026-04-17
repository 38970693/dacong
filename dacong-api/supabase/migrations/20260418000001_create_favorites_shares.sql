-- Migration: Create favorites and shares tables
-- Description: 实现内容收藏和分享功能

-- ============================================
-- favorites 表 - 用户收藏内容
-- ============================================
CREATE TABLE favorites (
  -- 主键
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- 关联
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content_id UUID NOT NULL REFERENCES published_content(id) ON DELETE CASCADE,

  -- 时间戳
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- 唯一约束：每个用户对每个内容只能收藏一次
  CONSTRAINT unique_user_content_favorite UNIQUE(user_id, content_id)
);

-- 索引
CREATE INDEX idx_favorites_user_id ON favorites(user_id, created_at DESC);
CREATE INDEX idx_favorites_content_id ON favorites(content_id);
CREATE INDEX idx_favorites_created_at ON favorites(created_at DESC);

-- 注释
COMMENT ON TABLE favorites IS '用户收藏的内容';
COMMENT ON COLUMN favorites.user_id IS '收藏用户ID';
COMMENT ON COLUMN favorites.content_id IS '被收藏的内容ID';

-- ============================================
-- shares 表 - 内容分享记录
-- ============================================
CREATE TABLE shares (
  -- 主键
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- 关联（user_id 可为空，支持匿名分享）
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  content_id UUID NOT NULL REFERENCES published_content(id) ON DELETE CASCADE,

  -- 分享平台
  platform VARCHAR(50) CHECK (platform IN ('system', 'wechat', 'weibo', 'twitter', 'facebook', 'linkedin', 'copy_link', 'other')),

  -- 时间戳
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_shares_content_id ON shares(content_id, created_at DESC);
CREATE INDEX idx_shares_user_id ON shares(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_shares_platform ON shares(platform, created_at DESC);
CREATE INDEX idx_shares_created_at ON shares(created_at DESC);

-- 注释
COMMENT ON TABLE shares IS '内容分享记录';
COMMENT ON COLUMN shares.user_id IS '分享用户ID（可为空，支持匿名分享）';
COMMENT ON COLUMN shares.content_id IS '被分享的内容ID';
COMMENT ON COLUMN shares.platform IS '分享平台：system/wechat/weibo/twitter/facebook/linkedin/copy_link/other';

-- ============================================
-- RLS 策略
-- ============================================

-- favorites 表 RLS
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

-- 用户可以查看自己的收藏
CREATE POLICY "Users can view their own favorites"
  ON favorites FOR SELECT
  USING (auth.uid() = user_id);

-- 用户可以添加收藏
CREATE POLICY "Users can insert their own favorites"
  ON favorites FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 用户可以删除自己的收藏
CREATE POLICY "Users can delete their own favorites"
  ON favorites FOR DELETE
  USING (auth.uid() = user_id);

-- shares 表 RLS
ALTER TABLE shares ENABLE ROW LEVEL SECURITY;

-- 所有人都可以插入分享记录（支持匿名分享）
CREATE POLICY "Anyone can insert share records"
  ON shares FOR INSERT
  WITH CHECK (true);

-- 用户可以查看自己的分享记录
CREATE POLICY "Users can view their own shares"
  ON shares FOR SELECT
  USING (auth.uid() = user_id OR user_id IS NULL);

-- ============================================
-- 触发器：更新 published_content.share_count
-- ============================================
CREATE OR REPLACE FUNCTION increment_share_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE published_content
  SET share_count = share_count + 1
  WHERE id = NEW.content_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_increment_share_count
  AFTER INSERT ON shares
  FOR EACH ROW
  EXECUTE FUNCTION increment_share_count();

-- ============================================
-- 视图：用户收藏内容详情
-- ============================================
CREATE OR REPLACE VIEW user_favorites_detail AS
SELECT
  f.id AS favorite_id,
  f.user_id,
  f.created_at AS favorited_at,
  pc.id AS content_id,
  pc.content_type,
  pc.title_zh,
  pc.summary_zh,
  pc.scenario,
  pc.view_count,
  pc.helpful_count,
  pc.share_count,
  pc.published_at
FROM favorites f
JOIN published_content pc ON f.content_id = pc.id
ORDER BY f.created_at DESC;

COMMENT ON VIEW user_favorites_detail IS '用户收藏内容详情视图';

-- ============================================
-- 视图：内容分享统计
-- ============================================
CREATE OR REPLACE VIEW content_share_stats AS
SELECT
  content_id,
  COUNT(*) AS total_shares,
  COUNT(DISTINCT user_id) AS unique_users,
  COUNT(*) FILTER (WHERE platform = 'wechat') AS wechat_shares,
  COUNT(*) FILTER (WHERE platform = 'weibo') AS weibo_shares,
  COUNT(*) FILTER (WHERE platform = 'twitter') AS twitter_shares,
  COUNT(*) FILTER (WHERE platform = 'facebook') AS facebook_shares,
  COUNT(*) FILTER (WHERE platform = 'linkedin') AS linkedin_shares,
  COUNT(*) FILTER (WHERE platform = 'copy_link') AS copy_link_shares,
  COUNT(*) FILTER (WHERE platform = 'system') AS system_shares,
  MAX(created_at) AS last_shared_at
FROM shares
GROUP BY content_id;

COMMENT ON VIEW content_share_stats IS '内容分享统计视图';
