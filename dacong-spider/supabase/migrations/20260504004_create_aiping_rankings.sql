-- =============================================
-- AI Ping Rankings Table
-- Migration: 20260504004_create_aiping_rankings
-- =============================================

BEGIN;

-- Create table
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

-- Indexes
CREATE INDEX IF NOT EXISTS idx_aiping_score ON aiping_rankings(overall_score DESC);
CREATE INDEX IF NOT EXISTS idx_aiping_fetched ON aiping_rankings(fetched_at DESC);
CREATE INDEX IF NOT EXISTS idx_aiping_model ON aiping_rankings(model_name);
CREATE INDEX IF NOT EXISTS idx_aiping_company ON aiping_rankings(company);
CREATE INDEX IF NOT EXISTS idx_aiping_scores ON aiping_rankings USING GIN (dimension_scores);

-- RLS Policies
ALTER TABLE aiping_rankings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "aiping_rankings_public_read" ON aiping_rankings;
CREATE POLICY "aiping_rankings_public_read" ON aiping_rankings
    FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "aiping_rankings_service_write" ON aiping_rankings;
CREATE POLICY "aiping_rankings_service_write" ON aiping_rankings
    FOR ALL TO service_role USING (true);

-- Comments
COMMENT ON TABLE aiping_rankings IS 'AI model rankings from aiping.dev';
COMMENT ON COLUMN aiping_rankings.dimension_scores IS 'JSON object with dimension-specific scores';
COMMENT ON COLUMN aiping_rankings.overall_score IS 'Overall score (0-100)';

COMMIT;