-- Migration: Create scenario_recommendations table
-- Description: 配置每个场景的推荐内容顺序

CREATE TABLE scenario_recommendations (
  -- 主键
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- 场景
  scenario TEXT NOT NULL CHECK (scenario IN ('coding', 'video', 'image', 'chat', 'writing', 'data')),

  -- 排序
  rank INT NOT NULL CHECK (rank > 0),

  -- 关联内容
  content_id UUID NOT NULL REFERENCES published_content(id) ON DELETE CASCADE,

  -- 状态
  active BOOLEAN DEFAULT TRUE,

  -- 时间戳
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- 唯一约束
  UNIQUE(scenario, rank)
);

-- 索引
CREATE INDEX idx_scenario_recommendations ON scenario_recommendations(scenario, rank) WHERE active;
CREATE INDEX idx_scenario_recommendations_content ON scenario_recommendations(content_id);

-- 注释
COMMENT ON TABLE scenario_recommendations IS '场景推荐配置表';
COMMENT ON COLUMN scenario_recommendations.rank IS '排序（1=最佳，2=平替，3=免费）';
