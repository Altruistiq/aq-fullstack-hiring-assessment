-- Migration tracking table only. Design your domain schema in subsequent migrations
-- (e.g. 002_schema.sql) — organizations, business_units, emission_factors, activities, etc.

CREATE TABLE IF NOT EXISTS _migrations (
  filename    TEXT PRIMARY KEY,
  applied_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
