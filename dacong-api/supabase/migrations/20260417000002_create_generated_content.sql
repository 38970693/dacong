-- Migration: Create generated_content table
-- Description: 存储AI生成的内容，等待人工审核

CREATE TABLE generated_content (
  -- 主键
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- 内容类型
  content_type TEXT NOT NULL CHECK (content_type IN ('recommendation', 'guide', 'comparison', 'weekly')),

  -- 中文内容（必填，主战场）
  title_zh TEXT NOT NULL,
  summary_zh TEXT,
  content_zh JSONB NOT NULL,

  -- 英文内容（AI翻译，副战场）
  title_en TEXT,
  summary_en TEXT,
  content_en JSONB,

  -- 关联数据
  source_data_ids UUID[],
  scenario TEXT CHECK (scenario IN ('coding', 'video', 'image', 'chat', 'writing', 'data')),

  -- AI质量指标
  ai_confidence FLOAT CHECK (ai_confidence >= 0 AND ai_confidence <= 1),
  quality_score FLOAT CHECK (quality_score >= 0 AND quality_score <= 1),

  -- 审核状态
  review_status TEXT DEFAULT 'pending' CHECK (review_status IN ('pending', 'approved', 'rejected', 'editing')),
  review_notes TEXT,

  -- 时间戳
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  reviewed_at TIMESTAMPTZ,
  reviewed_by UUID,

  -- 审计字段
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_generated_content_status ON generated_content(review_status, generated_at DESC);
CREATE INDEX idx_generated_content_type ON generated_content(content_type, review_status);
CREATE INDEX idx_generated_content_scenario ON generated_content(scenario) WHERE scenario IS NOT NULL;
CREATE INDEX idx_generated_content_quality ON generated_content(quality_score DESC, ai_confidence DESC);

-- 注释
COMMENT ON TABLE generated_content IS 'AI生成的内容，等待人工审核';
COMMENT ON COLUMN generated_content.content_zh IS '中文内容（JSONB），结构由content_type决定';
COMMENT ON COLUMN generated_content.content_en IS '英文内容（AI翻译）';
COMMENT ON COLUMN generated_content.ai_confidence IS 'AI自评置信度（0-1），低于0.85需人工审核';
COMMENT ON COLUMN generated_content.quality_score IS '自动质量评分（0-1），综合多个维度';
