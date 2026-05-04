-- =============================================
-- AI Rankings 完整迁移脚本
-- 执行方式：Supabase Dashboard > SQL Editor
-- =============================================

-- 1. SWE-bench Rankings 表
CREATE TABLE IF NOT EXISTS swebench_rankings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_name TEXT NOT NULL,
    elo_score NUMERIC(10, 4),
    pass_rate NUMERIC(5, 2),
    instance_count INTEGER,
    category TEXT DEFAULT 'standard',
    company TEXT,
    fetched_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT swebench_rankings_unique UNIQUE (model_name, category, fetched_at::date)
);

CREATE INDEX IF NOT EXISTS idx_swebench_elo ON swebench_rankings(elo_score DESC);
CREATE INDEX IF NOT EXISTS idx_swebench_fetched ON swebench_rankings(fetched_at DESC);
CREATE INDEX IF NOT EXISTS idx_swebench_model ON swebench_rankings(model_name);
CREATE INDEX IF NOT EXISTS idx_swebench_company ON swebench_rankings(company);

ALTER TABLE swebench_rankings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "swebench_rankings_public_read" ON swebench_rankings;
CREATE POLICY "swebench_rankings_public_read" ON swebench_rankings FOR SELECT TO public USING (true);
DROP POLICY IF EXISTS "swebench_rankings_service_write" ON swebench_rankings;
CREATE POLICY "swebench_rankings_service_write" ON swebench_rankings FOR ALL TO service_role USING (true);

-- 2. Arena Rankings 表
CREATE TABLE IF NOT EXISTS arena_rankings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_name TEXT NOT NULL,
    elo_score NUMERIC(10, 4),
    confidence_interval TEXT,
    vote_count INTEGER,
    category TEXT DEFAULT 'general',
    company TEXT,
    fetched_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT arena_rankings_unique UNIQUE (model_name, category, fetched_at::date)
);

CREATE INDEX IF NOT EXISTS idx_arena_elo ON arena_rankings(elo_score DESC);
CREATE INDEX IF NOT EXISTS idx_arena_fetched ON arena_rankings(fetched_at DESC);
CREATE INDEX IF NOT EXISTS idx_arena_model ON arena_rankings(model_name);
CREATE INDEX IF NOT EXISTS idx_arena_company ON arena_rankings(company);
CREATE INDEX IF NOT EXISTS idx_arena_category ON arena_rankings(category);

ALTER TABLE arena_rankings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "arena_rankings_public_read" ON arena_rankings;
CREATE POLICY "arena_rankings_public_read" ON arena_rankings FOR SELECT TO public USING (true);
DROP POLICY IF EXISTS "arena_rankings_service_write" ON arena_rankings;
CREATE POLICY "arena_rankings_service_write" ON arena_rankings FOR ALL TO service_role USING (true);

-- 3. Artificial Analysis Rankings 表
CREATE TABLE IF NOT EXISTS artificial_analysis_rankings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_name TEXT NOT NULL,
    overall_rank INTEGER,
    speed_score INTEGER,
    cost_score INTEGER,
    price_per_million_tokens NUMERIC(10, 2),
    context_window INTEGER,
    company TEXT,
    fetched_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT aa_rankings_unique UNIQUE (model_name, fetched_at::date)
);

CREATE INDEX IF NOT EXISTS idx_aa_rank ON artificial_analysis_rankings(overall_rank ASC);
CREATE INDEX IF NOT EXISTS idx_aa_fetched ON artificial_analysis_rankings(fetched_at DESC);
CREATE INDEX IF NOT EXISTS idx_aa_model ON artificial_analysis_rankings(model_name);
CREATE INDEX IF NOT EXISTS idx_aa_company ON artificial_analysis_rankings(company);
CREATE INDEX IF NOT EXISTS idx_aa_speed ON artificial_analysis_rankings(speed_score DESC);
CREATE INDEX IF NOT EXISTS idx_aa_cost ON artificial_analysis_rankings(cost_score DESC);

ALTER TABLE artificial_analysis_rankings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "artificial_analysis_public_read" ON artificial_analysis_rankings;
CREATE POLICY "artificial_analysis_public_read" ON artificial_analysis_rankings FOR SELECT TO public USING (true);
DROP POLICY IF EXISTS "artificial_analysis_service_write" ON artificial_analysis_rankings;
CREATE POLICY "artificial_analysis_service_write" ON artificial_analysis_rankings FOR ALL TO service_role USING (true);

-- 4. AI Ping Rankings 表
CREATE TABLE IF NOT EXISTS aiping_rankings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_name TEXT NOT NULL,
    company TEXT,
    overall_score NUMERIC(5, 2),
    dimension_scores JSONB DEFAULT '{}',
    fetched_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT aiping_rankings_unique UNIQUE (model_name, fetched_at::date)
);

CREATE INDEX IF NOT EXISTS idx_aiping_score ON aiping_rankings(overall_score DESC);
CREATE INDEX IF NOT EXISTS idx_aiping_fetched ON aiping_rankings(fetched_at DESC);
CREATE INDEX IF NOT EXISTS idx_aiping_model ON aiping_rankings(model_name);
CREATE INDEX IF NOT EXISTS idx_aiping_company ON aiping_rankings(company);
CREATE INDEX IF NOT EXISTS idx_aiping_scores ON aiping_rankings USING GIN (dimension_scores);

ALTER TABLE aiping_rankings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "aiping_rankings_public_read" ON aiping_rankings;
CREATE POLICY "aiping_rankings_public_read" ON aiping_rankings FOR SELECT TO public USING (true);
DROP POLICY IF EXISTS "aiping_rankings_service_write" ON aiping_rankings;
CREATE POLICY "aiping_rankings_service_write" ON aiping_rankings FOR ALL TO service_role USING (true);

-- 完成提示
SELECT 'AI Rankings 表创建完成！共 4 个表' AS status;