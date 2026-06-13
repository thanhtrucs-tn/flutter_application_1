-- ==========================================
-- MIGRATION 002: Add UNIQUE constraint on users.email
-- Database: test_123
-- Purpose: Ensure email is unique so users can log in with email reliably.
-- Safety: Existing NULL emails remain allowed; duplicate non-NULL emails will
--         cause the migration to fail and must be cleaned up manually first.
-- Note: For databases created with db_script.sql after 2026-06-14, this
--       migration is not needed because the script already defines the
--       UNIQUE(email) constraint. This migration is idempotent to avoid
--       creating a redundant index if it is accidentally re-run.
-- ==========================================

USE test_123;

SET @constraint_exists = (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE table_schema = DATABASE()
    AND table_name = 'users'
    AND index_name = 'unique_email'
);

SET @sql = IF(@constraint_exists = 0,
  'ALTER TABLE users ADD UNIQUE KEY unique_email (email)',
  'SELECT 1'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
