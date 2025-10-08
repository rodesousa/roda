-- ============================================
-- PostgreSQL Initialization Script
-- ============================================
-- Enable pgvector extension for vector similarity search
-- This script runs automatically when PostgreSQL container starts
-- Date: 2025-10-08

-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Verify extension is installed
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_extension WHERE extname = 'vector'
    ) THEN
        RAISE EXCEPTION 'pgvector extension installation failed!';
    END IF;

    RAISE NOTICE 'pgvector extension is installed successfully';
END $$;
