import * as fs from "fs";
import * as path from "path";
import { Client } from "pg";

const ROOT_DIR = process.cwd();
const MIGRATIONS_DIR = path.join(ROOT_DIR, "migrations");

function loadEnv(): Record<string, string> {
  const envPath = path.join(ROOT_DIR, ".env");
  if (!fs.existsSync(envPath)) {
    console.error(".env not found.");
    process.exit(1);
  }
  const env: Record<string, string> = {};
  for (const line of fs.readFileSync(envPath, "utf-8").split("\n")) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const eq = trimmed.indexOf("=");
    if (eq === -1) continue;
    env[trimmed.slice(0, eq).trim()] = trimmed.slice(eq + 1).trim();
  }
  return env;
}

async function main(): Promise<void> {
  const steps = Number(process.argv[2] ?? 1);
  if (!Number.isInteger(steps) || steps < 1) {
    console.error("Usage: npm run rollback [N]  (N = number of migrations to revert, default 1)");
    process.exit(1);
  }

  const env = loadEnv();
  const client = new Client({
    host: env.DB_HOST ?? "localhost",
    port: Number(env.DB_PORT ?? 5432),
    database: env.DB_NAME,
    user: env.DB_USER,
    password: env.DB_PASSWORD,
  });

  await client.connect();

  const tableCheck = await client.query<{ exists: boolean }>(
    "SELECT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'migrations') AS exists"
  );
  if (!tableCheck.rows[0].exists) {
    console.log("No applied migrations to revert.");
    await client.end();
    return;
  }

  const result = await client.query<{ migration: string }>(
    "SELECT migration FROM migrations ORDER BY migration DESC LIMIT $1",
    [steps]
  );

  if (result.rows.length === 0) {
    console.log("No applied migrations to revert.");
    await client.end();
    return;
  }

  // The whole run is one transaction: if any down.sql in this batch fails, every
  // migration reverted earlier in the same run is rolled back too.
  await client.query("BEGIN");
  try {
    for (const { migration } of result.rows) {
      const downPath = path.join(MIGRATIONS_DIR, migration, "down.sql");
      if (!fs.existsSync(downPath)) {
        throw new Error(`No down.sql for migration: ${migration}`);
      }
      const sql = fs.readFileSync(downPath, "utf-8");
      console.log(`Reverting: ${migration}`);
      await client.query("DELETE FROM migrations WHERE migration = $1", [migration]);
      await client.query(sql);
      console.log(`  ✓ Reverted`);
    }
    await client.query("COMMIT");
  } catch (err) {
    await client.query("ROLLBACK");
    console.error(`  ✗ Failed — rolled back the whole batch`);
    console.error(err);
    await client.end();
    process.exit(1);
  }

  console.log(`\nReverted ${result.rows.length} migration(s).`);
  await client.end();
}

main();
