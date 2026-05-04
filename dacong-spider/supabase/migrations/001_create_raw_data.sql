-- Migration: Create raw_data table for dacong-spider
-- This table stores scraped raw data from various sources

CREATE TABLE IF NOT EXISTS raw_data (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Data source identification
    source TEXT NOT NULL,
    source_id TEXT NOT NULL,
    data_type TEXT NOT NULL DEFAULT 'content',

    -- Content fields
    title TEXT,
    description TEXT,
    url TEXT,
    metadata JSONB DEFAULT '{}',
    raw_content TEXT,

    -- Content hash for deduplication
    content_hash TEXT,

    -- Timestamps
    fetched_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Unique constraint for upsert
    CONSTRAINT raw_data_unique_source_id UNIQUE (source, source_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_raw_data_source ON raw_data(source);
CREATE INDEX IF NOT EXISTS idx_raw_data_source_id ON raw_data(source_id);
CREATE INDEX IF NOT EXISTS idx_raw_data_source_source_id ON raw_data(source, source_id);
CREATE INDEX IF NOT EXISTS idx_raw_data_content_hash ON raw_data(content_hash);
CREATE INDEX IF NOT EXISTS idx_raw_data_fetched_at ON raw_data(fetched_at DESC);
CREATE INDEX IF NOT EXISTS idx_raw_data_created_at ON raw_data(created_at DESC);

-- Comments
COMMENT ON TABLE raw_data IS 'Raw scraped data from various sources';
COMMENT ON COLUMN raw_data.source IS 'Source identifier: github, huggingface, hackernews, etc.';
COMMENT ON COLUMN raw_data.source_id IS 'Unique ID from the source website';
COMMENT ON COLUMN raw_data.data_type IS 'Type of data: content, model, tool, etc.';
COMMENT ON COLUMN raw_data.content_hash IS 'Hash of the content for deduplication';