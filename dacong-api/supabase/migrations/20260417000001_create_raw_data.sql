-- Migration: Create raw_data table
-- Description: 存储爬虫采集的原始数据

CREATE TABLE raw_data (
  -- 主键
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- 数据来源
  source TEXT NOT NULL CHECK (source IN ('github', 'huggingface', 'openrouter', 'reddit', 'twitter')),
  data_type TEXT NOT NULL CHECK (data_type IN ('model', 'tool', 'price', 'discussion', 'news')),

  -- 原始数据（JSONB格式，灵活存储）
  raw_json JSONB NOT NULL,

  -- 元数据
  fetched_at TIMESTAMPTZ DEFAULT NOW(),
  processed BOOLEAN DEFAULT FALSE,
  processed_at TIMESTAMPTZ,

  -- 审计字段
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_raw_data_source ON raw_data(source, fetched_at DESC);
CREATE INDEX idx_raw_data_processed ON raw_data(processed, created_at DESC) WHERE NOT processed;
CREATE INDEX idx_raw_data_type ON raw_data(data_type, source);

-- 注释
COMMENT ON TABLE raw_data IS '爬虫采集的原始数据';
COMMENT ON COLUMN raw_data.source IS '数据来源：github/huggingface/openrouter等';
COMMENT ON COLUMN raw_data.data_type IS '数据类型：model/tool/price等';
COMMENT ON COLUMN raw_data.raw_json IS '原始JSON数据，结构由source决定';
