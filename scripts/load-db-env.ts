import * as fs from "fs";
import * as path from "path";

const REQUIRED_KEYS = ["DB_NAME", "DB_USER", "DB_PASSWORD"] as const;
const KNOWN_KEYS = ["DB_HOST", "DB_PORT", ...REQUIRED_KEYS] as const;

// Real environment variables always win over a committed .env file, so this works unchanged on
// any platform that injects config as env vars (no .env file needed there) and still supports the
// local convenience of a .env file when developing on a machine.
export function loadDbEnv(): Record<string, string> {
  const envPath = path.join(process.cwd(), ".env");
  const env: Record<string, string> = {};

  if (fs.existsSync(envPath)) {
    for (const line of fs.readFileSync(envPath, "utf-8").split("\n")) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith("#")) continue;
      const eq = trimmed.indexOf("=");
      if (eq === -1) continue;
      env[trimmed.slice(0, eq).trim()] = trimmed.slice(eq + 1).trim();
    }
  }

  for (const key of KNOWN_KEYS) {
    if (process.env[key] !== undefined) env[key] = process.env[key]!;
  }

  const missing = REQUIRED_KEYS.filter((key) => !env[key]);
  if (missing.length > 0) {
    console.error(
      `Missing DB credentials: ${missing.join(", ")}. Set them as environment variables, or copy .env.example to .env and fill them in.`,
    );
    process.exit(1);
  }

  return env;
}
