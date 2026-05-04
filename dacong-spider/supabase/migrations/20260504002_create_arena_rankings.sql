-- =============================================
-- Arena.ai Rankings Table
-- Migration: 20260504002_create_arena_rankings
-- =============================================

BEGIN;

-- Create table
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

-- Indexes
CREATE INDEX IF NOT EXISTS idx_arena_elo ON arena_rankings(elo_score DESC);
CREATE INDEX IF NOT EXISTS idx_arena_fetched ON arena_rankings(fetched_at DESC);
CREATE INDEX IF NOT EXISTS idx_arena_model ON arena_rankings(model_name);
CREATE INDEX IF NOT EXISTS idx_arena_company ON arena_rankings(company);
CREATE INDEX IF NOT EXISTS idx_arena_category ON arena_rankings(category);

-- RLS Policies
ALTER TABLE arena_rankings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "arena_rankings_public_read" ON arena_rankings;
CREATE POLICY "arena_rankings_public_read" ON arena_rankings
    FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "arena_rankings_service_write" ON arena_rankings;
CREATE POLICY "arena_rankings_service_write" ON arena_rankings
    FOR ALL TO service_role USING (true);

-- Comments
COMMENT ON TABLE arena_rankings IS 'LMArena benchmark rankings from lmarena.ai';
COMMENT ON COLUMN arena_rankings.confidence_interval IS 'Confidence interval string (e.g., +/-5)';
COMMENT ON COLUMN arena_rankings.vote_count IS 'Number of votes received';

COMMIT;