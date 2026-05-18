# Migrations

Plain SQL files applied in filename order by `scripts/migrate.ts`. Each filename is recorded in `_migrations` once successfully applied, and skipped on subsequent runs.

## Conventions

- Use a numeric prefix and a short kebab-case suffix: `002_schema.sql`, `003_indexes.sql`, etc.
- Each file should be runnable as a single SQL block (the runner sends the whole file in one query). Wrap multi-statement files in `BEGIN; ... COMMIT;` if you want atomicity.
- Migrations are forward-only — to revert a change, write a new migration.

## Running

```
npm run migrate
```

The runner reads `DATABASE_URL` from the environment (see `.env.example`).
