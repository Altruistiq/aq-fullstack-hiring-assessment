# AQ Full-Stack Assessment 2026

Starter repository for the emissions-tracking assessment. The brief will be delivered separately.

## Prerequisites

- Node 20+
- npm 10+
- Docker (for local Postgres)

## Quick start

```
npm install
cp .env.example .env
npm run db:up         # start Postgres 16 on :5433
npm run migrate       # runs migrations/*.sql in order
npm run dev           # backend on :3000, frontend on :5173
```

Open <http://localhost:5173>. The page shows the status returned by the backend's `/health` endpoint via the Vite dev proxy.

**Correctness contract:** `tests/fixtures/expected_totals.json` is the ground truth for your reporting endpoint. Your numbers must match within 0.5% (tolerance specified in the fixture).

## Scripts

| Script              | What it does                                                    |
| ------------------- | --------------------------------------------------------------- |
| `npm run dev`       | Runs api (tsx watch) and web (vite) concurrently                |
| `npm run build`     | Builds both workspaces                                          |
| `npm test`          | Runs vitest in each workspace                                   |
| `npm run lint`      | Runs ESLint across the repo                                     |
| `npm run typecheck` | Runs TypeScript in each workspace                               |
| `npm run migrate`   | Applies `migrations/*.sql` to `DATABASE_URL`                    |
| `npm run seed`      | Stub — you'll implement loading the CSVs in `seed/`             |
| `npm run db:up`     | `docker compose up -d`                                          |
| `npm run db:down`   | `docker compose down`                                           |

## Repo tour

- `api/` — Express + postgres.js backend. App factory is in `api/src/app.ts`; `server.ts` binds the port.
- `web/` — Vue 3 + Vite frontend. Vite proxies `/api/*` → backend in dev.
- `migrations/` — plain SQL applied in filename order by `scripts/migrate.ts`. Design your schema here.
- `scripts/` — `migrate.ts` (working) and `seed.ts` (stub).
- `seed/` — CSV fixtures: `business_units.csv`, `emission_factors.csv`, `activities.csv`.
- `tests/fixtures/expected_totals.json` — ground-truth totals for the year 2024; your reporting endpoint must match within 0.5%.
- `docker-compose.yml` — Postgres 16 on host port `5433`.

## Notes

- The assessment brief is delivered separately. Please read it carefully before coding.
- Save your AI prompt transcript and submit it alongside your code.
