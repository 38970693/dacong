-- Migration: Create published_content table
-- Description: 存储已发布的内容，供客户端展示

CREATE TABLE published_content (
  -- 主键
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- 关联
  generated_content_id UUID REFERENCES generated_content(id) ON DELETE SET NULL,

  -- 内容类型
  content_type TEXT NOT NULL CHECK (content_type IN ('recommendation', 'guide', 'comparison', 'weekly')),

  -- 中文内容
  title_zh TEXT NOT NULL,
  summary_zh TEXT,
  content_zh JSONB NOT NULL,

  -- 英文内容
  title_en TEXT,
  summary_en TEXT,
  content_en JSONB,

  -- 场景
  scenario TEXT CHECK (scenario IN ('coding', 'video', 'image', 'chat', 'writing', 'data')),

  -- 统计数据
  view_count INT DEFAULT 0 CHECK (view_count >= 0),
  helpful_count INT DEFAULT 0 CHECK (helpful_count >= 0),
  unhelpful_count INT DEFAULT 0 CHECK (unhelpful_count >= 0),
  share_count INT DEFAULT 0 CHECK (share_count >= 0),

  -- 时间戳
  published_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- 审计字段
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_published_content_type ON published_content(content_type, published_at DESC);
CREATE INDEX idx_published_content_scenario ON published_content(scenario, published_at DESC) WHERE scenario IS NOT NULL;
CREATE INDEX idx_published_content_popular ON published_content(helpful_count DESC, view_count DESC);
CREATE INDEX idx_published_content_updated ON published_content(updated_at DESC);

-- 全文搜索索引（中文）
CREATE INDEX idx_published_content_search_zh ON published_content USING gin(to_tsvector('simple', title_zh || ' ' || COALESCE(summary_zh, '')));

-- 全文搜索索引（英文）
CREATE INDEX idx_published_content_search_en ON published_content USING gin(to_tsvector('english', COALESCE(title_en, '') || ' ' || COALESCE(summary_en, '')));

-- JSONB索引
CREATE INDEX idx_published_content_zh_gin ON published_content USING gin(content_zh);
CREATE INDEX idx_published_content_en_gin ON published_content USING gin(content_en);

-- 注释
COMMENT ON TABLE published_content IS '已发布的内容，供客户端展示';
COMMENT ON COLUMN published_content.helpful_count IS '用户点击"有用"的次数';
COMMENT ON COLUMN published_content.unhelpful_count IS '用户点击"无用"的次数';
