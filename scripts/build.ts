import * as fs from "fs";
import * as path from "path";

const ROOT_DIR = process.cwd();
const OUTPUT_FILE = "db-output.sql";
const ROOT_INIT = "init.sql";
const MIGRATIONS_DIR = "migrations";
const visited = new Set<string>();

// schema/ already reflects every migration (the project's own convention — see the matching
// schema/ edit rule in .claude/CLAUDE.md), so db-output.sql builds the up-to-date shape directly
// from schema/, never by replaying migrations/. But scripts/migrate.ts decides what is "pending"
// from the `migrations` tracking table, which a fresh load of db-output.sql never populates — so
// the very first `npm run migrate` after bootstrapping from db-output.sql would try to re-apply
// every migration against a schema that already has them, and fail. Recording them as already
// applied here keeps the two mechanisms in sync.
function migrationTrackingSql(): string[] {
  if (!fs.existsSync(MIGRATIONS_DIR)) return [];
  const names = fs
    .readdirSync(MIGRATIONS_DIR)
    .filter((name) => fs.statSync(path.join(MIGRATIONS_DIR, name)).isDirectory())
    .sort();
  if (names.length === 0) return [];

  const values = names.map((name) => `    ('${name}')`).join(",\n");
  return [
    "",
    "-- [migrations tracking] -----------------------------------",
    "-- Every migration folder above is already reflected in schema/ (see build.ts); mark them as",
    "-- applied so the first `npm run migrate` after this load does not try to redo them.",
    "CREATE TABLE IF NOT EXISTS migrations (",
    "    migration   VARCHAR(255) PRIMARY KEY,",
    "    applied_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()",
    ");",
    "INSERT INTO migrations (migration) VALUES",
    `${values}`,
    "ON CONFLICT (migration) DO NOTHING;",
    "-- [/migrations tracking]\n",
  ];
}

function readLines(filePath: string): string[] {
  if (!fs.existsSync(filePath)) {
    console.warn(`[WARN] Not found: ${filePath}`);
    return [];
  }
  return fs.readFileSync(filePath, "utf-8").split("\n").map((l) => l.trimEnd());
}

function sectionLabel(initPath: string): string {
  const rel = path.relative(ROOT_DIR, path.dirname(path.resolve(initPath)));
  return rel.replace(/[\\/]/g, " > ") || ".";
}

function processInit(initPath: string): string[] {
  const absPath = path.resolve(initPath);
  if (visited.has(absPath)) return [];
  visited.add(absPath);

  const output: string[] = [];
  for (const line of readLines(absPath)) {
    const match = line.match(/^\s*\\i\s+(.+)/);
    if (!match) {
      output.push(line);
      continue;
    }
    const ref = match[1].trim();
    const refPath = path.join(ROOT_DIR, ref);

    if (ref.endsWith("init.sql")) {
      const lbl = sectionLabel(refPath);
      const dashes = "-".repeat(Math.max(2, 54 - lbl.length));
      output.push(`\n-- [${lbl}] ${dashes}`);
      output.push(...processInit(refPath));
      output.push(`-- [/${lbl}]\n`);
    } else {
      output.push(...readLines(refPath));
    }
  }
  return output;
}

const now = new Date().toISOString().replace("T", " ").slice(0, 19);
const header = [
  "-- " + "=".repeat(58),
  `-- Generated: ${now}`,
  "-- DO NOT EDIT — run: npm run build",
  "-- " + "=".repeat(58),
  "",
];

if (fs.existsSync(OUTPUT_FILE)) fs.unlinkSync(OUTPUT_FILE);
const lines = processInit(ROOT_INIT);
fs.writeFileSync(OUTPUT_FILE, [...header, ...lines, ...migrationTrackingSql()].join("\n") + "\n", "utf-8");
console.log(`Generated: ${OUTPUT_FILE}`);
