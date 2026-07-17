-- migration: create core tables for the local DB
-- Run this SQL against the app database when performing manual migrations.

PRAGMA foreign_keys = OFF;

BEGIN TRANSACTION;

-- V1: initial core tables
CREATE TABLE IF NOT EXISTS pending_inspections (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  payload TEXT NOT NULL,
  status TEXT NOT NULL,
  created_at INTEGER NOT NULL
);

-- Pending submissions table: used by the worker_demo example to queue
-- failed HTTP submissions for background retry.
CREATE TABLE IF NOT EXISTS pending_submissions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  payload TEXT NOT NULL,
  status TEXT NOT NULL,
  created_at INTEGER NOT NULL
);

-- V2: ensure master_inspections index table exists
CREATE TABLE IF NOT EXISTS master_inspections (
  hseFormId TEXT PRIMARY KEY,
  payload TEXT NOT NULL,
  updated_at INTEGER NOT NULL,
  formType TEXT DEFAULT ''
);

-- V2: auxiliary full-form table
CREATE TABLE IF NOT EXISTS master_inspection_forms (
  hseFormId TEXT PRIMARY KEY,
  payload TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);

-- V2: asset table
CREATE TABLE IF NOT EXISTS asset (
  assetId TEXT PRIMARY KEY,
  payload TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS notifications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT,
  body TEXT,
  data TEXT,
  created_at INTEGER NOT NULL,
  read INTEGER DEFAULT 0
);

COMMIT;

