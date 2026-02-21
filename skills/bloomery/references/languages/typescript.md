# TypeScript Setup

## Runtime

**Recommended: `npx tsx`** (zero config, runs TypeScript directly).

```bash
mkdir <agent-name> && cd <agent-name>
```

Create `agent.ts` and run with:
```bash
npx tsx agent.ts
```

No `package.json`, no `tsconfig.json`, no compilation step. `tsx` handles everything.

**Alternative runtimes** (mention if the user prefers):
- **Bun**: `bun run agent.ts` (also zero config)
- **Node 23+**: `node --experimental-strip-types agent.ts`
- **Node + tsc**: Requires `package.json` with `"type": "module"`, `tsconfig.json` — more setup, skip unless they specifically want it.

## Standard Library Modules

All built-in, no npm install needed:

| Need | Import |
|------|--------|
| HTTP | `fetch` (global, built-in) |
| Stdin | `import * as readline from "node:readline"` |
| Run commands | `import { execSync } from "node:child_process"` |
| Files | `import { readFileSync, writeFileSync, readdirSync } from "node:fs"` |
| JSON | Built-in `JSON.parse` / `JSON.stringify` |

## Starter File

Write this as `agent.ts`. Replace `GEMINI_API_KEY` with the correct env var for the chosen provider (see Provider Env Vars in SKILL.md). For OpenAI, also add `BASE_URL` and `MODEL` variables after the API key check.

```typescript
import * as readline from "node:readline";
import { readFileSync } from "node:fs";

// Load .env file
const env = readFileSync(".env", "utf-8");
for (const line of env.split("\n")) {
  const [key, ...vals] = line.split("=");
  if (key?.trim() && vals.length) {
    const v = vals.join("=").trim();
    if (v && !v.startsWith("#")) process.env[key.trim()] = v;
  }
}

const API_KEY = process.env.GEMINI_API_KEY;
if (!API_KEY) {
  console.error("Missing GEMINI_API_KEY in .env file");
  process.exit(1);
}

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const prompt = (q: string): Promise<string> =>
  new Promise((resolve) => rl.question(q, resolve));

async function main() {
  while (true) {
    const input = await prompt("> ");
    // TODO: send to LLM API and print response
  }
}

main().catch(console.error);
```

## Language Hints for Specific Steps

### Step 7 (Bash Tool): `execSync` throws on non-zero exit codes
Unlike most languages, Node's `execSync` throws an error when a command exits with a non-zero code. The error object has `stdout`, `stderr`, and `status` properties with the output. The user needs to wrap the call in try/catch and extract output from the error object on failure. This is the key gotcha — without the catch, commands like `grep` (exit 1 = no matches) will crash the agent.

## OpenAI Variant

For **OpenAI**, add after the API_KEY check:
```typescript
const BASE_URL = process.env.OPENAI_BASE_URL || "https://api.openai.com/v1";
const MODEL = process.env.MODEL_NAME || "gpt-4o";
```
