-- =============================================
-- Artificial Analysis Rankings Table
-- Migration: 20260504003_create_artificial_analysis_rankings
-- =============================================

BEGIN;

-- Create table
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
    CONSTRAINT artificial_analysis_rankings_unique UNIQUE (model_name, fetched_at::date)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_aa_rank ON artificial_analysis_rankings(overall_rank ASC);
CREATE INDEX IF NOT EXISTS idx_aa_fetched ON artificial_analysis_rankings(fetched_at DESC);
CREATE INDEX IF NOT EXISTS idx_aa_model ON artificial_analysis_rankings(model_name);
CREATE INDEX IF NOT EXISTS idx_aa_company ON artificial_analysis_rankings(company);
CREATE INDEX IF NOT EXISTS idx_aa_speed ON artificial_analysis_rankings(speed_score DESC);
CREATE INDEX IF NOT EXISTS idx_aa_cost ON artificial_analysis_rankings(cost_score DESC);

-- RLS Policies
ALTER TABLE artificial_analysis_rankings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "artificial_analysis_rankings_public_read" ON artificial_analysis_rankings;
CREATE POLICY "artificial_analysis_rankings_public_read" ON artificial_analysis_rankings
    FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "artificial_analysis_rankings_service_write" ON artificial_analysis_rankings;
CREATE POLICY "artificial_analysis_rankings_service_write" ON artificial_analysis_rankings
    FOR ALL TO service_role USING (true);

-- Comments
COMMENT ON TABLE artificial_analysis_rankings IS 'AI model rankings from artificialanalysis.ai';
COMMENT ON COLUMN artificial_analysis_rankings.speed_score IS 'Response speed score (1-100)';
COMMENT ON COLUMN artificial_analysis_rankings.cost_score IS 'Cost efficiency score (1-100)';
COMMENT ON COLUMN artificial_analysis_rankings.context_window IS 'Maximum context window size in tokens';

COMMIT;