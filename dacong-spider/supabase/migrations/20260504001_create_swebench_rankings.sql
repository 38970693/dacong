-- =============================================
-- SWE-bench Rankings Table
-- Migration: 20260504001_create_swebench_rankings
-- =============================================

BEGIN;

-- Create table
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

-- Indexes
CREATE INDEX IF NOT EXISTS idx_swebench_elo ON swebench_rankings(elo_score DESC);
CREATE INDEX IF NOT EXISTS idx_swebench_fetched ON swebench_rankings(fetched_at DESC);
CREATE INDEX IF NOT EXISTS idx_swebench_model ON swebench_rankings(model_name);
CREATE INDEX IF NOT EXISTS idx_swebench_company ON swebench_rankings(company);

-- RLS Policies
ALTER TABLE swebench_rankings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "swebench_rankings_public_read" ON swebench_rankings;
CREATE POLICY "swebench_rankings_public_read" ON swebench_rankings
    FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "swebench_rankings_service_write" ON swebench_rankings;
CREATE POLICY "swebench_rankings_service_write" ON swebench_rankings
    FOR ALL TO service_role USING (true);

-- Comments
COMMENT ON TABLE swebench_rankings IS 'SWE-bench benchmark rankings from swe-bench.org';
COMMENT ON COLUMN swebench_rankings.elo_score IS 'ELO rating score';
COMMENT ON COLUMN swebench_rankings.pass_rate IS 'Pass rate percentage (0-100)';
COMMENT ON COLUMN swebench_rankings.instance_count IS 'Number of benchmark instances';

-- 30-day auto-cleanup trigger
CREATE OR REPLACE FUNCTION cleanup_swebench_rankings()
RETURNS void AS $$
BEGIN
    DELETE FROM swebench_rankings
    WHERE fetched_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION cleanup_swebench_rankings() IS 'Cleanup records older than 30 days';

COMMIT;