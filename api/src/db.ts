import postgres from "postgres";
import { config } from "./config.js";

export const sql = postgres(config.databaseUrl, {
  max: 10,
  onnotice: () => {},
});

export async function pingDb(): Promise<boolean> {
  try {
    const rows = await sql<{ ok: number }[]>`SELECT 1 AS ok`;
    return rows[0]?.ok === 1;
  } catch {
    return false;
  }
}
