import { readdirSync, readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { config as loadEnv } from "dotenv";
import postgres from "postgres";

const __dirname = dirname(fileURLToPath(import.meta.url));
loadEnv({ path: join(__dirname, "..", ".env"), quiet: true });

const MIGRATIONS_DIR = join(__dirname, "..", "migrations");

const DATABASE_URL = process.env.DATABASE_URL;
if (!DATABASE_URL) {
  console.error("DATABASE_URL is not set. Copy .env.example to .env or export it before running.");
  process.exit(1);
}

const sql = postgres(DATABASE_URL, { max: 1, onnotice: () => {} });

async function ensureTrackingTable(): Promise<void> {
  await sql`
    CREATE TABLE IF NOT EXISTS _migrations (
      filename    TEXT PRIMARY KEY,
      applied_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `;
}

async function appliedFilenames(): Promise<Set<string>> {
  const rows = await sql<{ filename: string }[]>`SELECT filename FROM _migrations`;
  return new Set(rows.map((r) => r.filename));
}

async function run(): Promise<void> {
  await ensureTrackingTable();
  const applied = await appliedFilenames();

  const files = readdirSync(MIGRATIONS_DIR)
    .filter((f) => f.endsWith(".sql"))
    .sort();

  let appliedCount = 0;
  for (const filename of files) {
    if (applied.has(filename)) {
      console.log(`skip   ${filename}`);
      continue;
    }
    const fullPath = join(MIGRATIONS_DIR, filename);
    const body = readFileSync(fullPath, "utf8");
    console.log(`apply  ${filename}`);
    await sql.unsafe(body);
    await sql`INSERT INTO _migrations (filename) VALUES (${filename})`;
    appliedCount++;
  }

  console.log(`done   (${appliedCount} new, ${files.length - appliedCount} already applied)`);
}

try {
  await run();
} catch (err) {
  console.error("migration failed:", err);
  process.exitCode = 1;
} finally {
  await sql.end({ timeout: 5 });
}
