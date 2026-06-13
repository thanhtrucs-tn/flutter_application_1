-- ==========================================
-- MIGRATION 001: Add user profile columns to users table
-- Database: test_123
-- Purpose: Add name, email, phone to an existing users table without data loss.
-- Safety: Columns are nullable with no default; existing rows become NULL for these columns.
-- Note: This migration assumes the users table was created before name/email/phone existed.
-- ==========================================

USE test_123;

ALTER TABLE users
  ADD COLUMN name VARCHAR(100) NULL AFTER password,
  ADD COLUMN email VARCHAR(48) NULL AFTER name,
  ADD COLUMN phone VARCHAR(10) NULL AFTER email;
