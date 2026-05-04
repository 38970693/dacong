-- Migration: Add missing columns to posts table
-- Created: 2026-05-04

-- Add favorites_count column if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'posts' AND column_name = 'favorites_count'
    ) THEN
        ALTER TABLE posts ADD COLUMN favorites_count INTEGER DEFAULT 0;
    END IF;
END;
$$;

-- Add views_count column if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'posts' AND column_name = 'views_count'
    ) THEN
        ALTER TABLE posts ADD COLUMN views_count INTEGER DEFAULT 0;
    END IF;
END;
$$;

-- Add comments_count column if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'posts' AND column_name = 'comments_count'
    ) THEN
        ALTER TABLE posts ADD COLUMN comments_count INTEGER DEFAULT 0;
    END IF;
END;
$$;

-- Add summary column (for AI-generated summary)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'posts' AND column_name = 'summary'
    ) THEN
        ALTER TABLE posts ADD COLUMN summary TEXT;
    END IF;
END;
$$;

-- Add is_featured column
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'posts' AND column_name = 'is_featured'
    ) THEN
        ALTER TABLE posts ADD COLUMN is_featured BOOLEAN DEFAULT FALSE;
    END IF;
END;
$$;