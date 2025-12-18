-- Mini Mart POS Database Initialization Script
-- This script is automatically run when the PostgreSQL container starts for the first time

-- Create the main database (already created by POSTGRES_DB env var)
-- Additional setup can be added here if needed

\c mini_mart_pos;

-- Set up timezone and basic configuration
SET timezone = 'UTC';

-- Create extensions if needed
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Log successful initialization
DO $$
BEGIN
    RAISE NOTICE 'Mini Mart POS database initialized successfully';
END $$;
