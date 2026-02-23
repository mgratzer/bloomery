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

const API_KEY = process.env.{{API_KEY_VAR}};
if (!API_KEY) {
  console.error("Missing {{API_KEY_VAR}} in .env file");
  process.exit(1);
}
{{#OPENAI}}

const BASE_URL = process.env.OPENAI_BASE_URL || "https://api.openai.com/v1";
const MODEL = process.env.MODEL_NAME || "gpt-4o";
{{/OPENAI}}

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
