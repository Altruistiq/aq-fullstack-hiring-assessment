BEGIN;

-- ─── Business Units ──────────────────────────────────────────────────────────
-- Hierarchical org structure: EMEA → UK/NL/DE Region → Offices
-- String IDs match the CSV directly (bu-1, bu-2 etc) — no UUID mapping needed
-- depth: 0 = root (EMEA), 1 = region, 2 = leaf office — used for UI ordering
CREATE TABLE business_units (
  id        TEXT PRIMARY KEY,
  name      TEXT     NOT NULL,
  parent_id TEXT     REFERENCES business_units(id),
  region    TEXT     NOT NULL,
  depth     SMALLINT NOT NULL DEFAULT 0
);

-- ─── Emission Factors ────────────────────────────────────────────────────────
-- Time-bounded, region-scoped conversion rates (kg CO2e per unit of activity)
-- When two rows overlap the same period, the NARROWER date range wins (specificity rule)
-- UNIQUE prevents duplicate seeding; CHECKs guard data integrity at DB level
CREATE TABLE emission_factors (
  id               SERIAL  PRIMARY KEY,
  activity_type    TEXT    NOT NULL,
  region           TEXT    NOT NULL,
  valid_from       DATE    NOT NULL,
  valid_to         DATE    NOT NULL,
  kg_co2e_per_unit NUMERIC(14,6) NOT NULL,
  unit             TEXT    NOT NULL,
  source           TEXT,
  UNIQUE (activity_type, region, valid_from, valid_to),
  CHECK  (valid_from < valid_to),
  CHECK  (kg_co2e_per_unit > 0)
);

-- ─── Upload Batches ──────────────────────────────────────────────────────────
-- Tracks every CSV upload for idempotency and auditability
-- file_hash (SHA-256): same file uploaded twice → return existing result, skip reprocessing
-- accepted_count / rejected_count: populated after processing, surfaced in UI
-- error_message: populated when status = 'failed' for debugging
CREATE TABLE upload_batches (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  filename       TEXT        NOT NULL,
  file_hash      TEXT        NOT NULL UNIQUE,
  uploaded_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status         TEXT        NOT NULL DEFAULT 'pending',
  accepted_count INTEGER,
  rejected_count INTEGER,
  error_message  TEXT,
  CHECK (status IN ('pending', 'processed', 'failed'))
);

-- ─── Activities ──────────────────────────────────────────────────────────────
-- Clean, validated activity records only — bad rows go to ingestion_issues
-- region is denormalized from business_units to eliminate a correlated subquery
-- inside the LATERAL emission factor lookup (one fewer subquery per row at query time)
-- quantity >= 0 enforced at DB level (app-level validation is the first line of defence)
CREATE TABLE activities (
  id               UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  business_unit_id TEXT    NOT NULL REFERENCES business_units(id),
  region           TEXT    NOT NULL,
  activity_type    TEXT    NOT NULL,
  quantity         NUMERIC(14,6) NOT NULL,
  unit             TEXT    NOT NULL,
  activity_date    DATE    NOT NULL,
  source_ref       TEXT,
  upload_batch_id  UUID    REFERENCES upload_batches(id),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (quantity >= 0)
);

-- ─── Ingestion Issues ────────────────────────────────────────────────────────
-- Every row that could not be fully processed lands here — nothing is silently dropped
-- reason_code: machine-readable slug for filtering (unknown_business_unit etc)
-- reason_detail: human-readable message shown in the UI
-- status: 'rejected' = row discarded | 'corrected' = row accepted after transformation (e.g. MWh→kWh)
CREATE TABLE ingestion_issues (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  upload_batch_id UUID        REFERENCES upload_batches(id),
  raw_row         JSONB       NOT NULL,
  reason_code     TEXT        NOT NULL,
  reason_detail   TEXT        NOT NULL,
  status          TEXT        NOT NULL DEFAULT 'rejected',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (status IN ('rejected', 'corrected'))
);

-- ─── Indexes ─────────────────────────────────────────────────────────────────

-- Reporting query: date range filter + BU join + activity_type — all in one compound seek
CREATE INDEX ON activities (activity_date, business_unit_id, activity_type);

-- LATERAL emission factor lookup uses activity_type + region from the activities row
CREATE INDEX ON activities (activity_type, region);

-- Emission factor LATERAL: all 4 cols needed to find the right versioned factor
CREATE INDEX ON emission_factors (activity_type, region, valid_from, valid_to);

-- Recursive CTE tree walk (parent → children)
CREATE INDEX ON business_units (parent_id);

-- Batch-scoped queries: fetch all issues or activities for a given upload
CREATE INDEX ON ingestion_issues (upload_batch_id);
CREATE INDEX ON activities (upload_batch_id);

COMMIT;
