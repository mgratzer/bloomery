#!/usr/bin/env bash
set -euo pipefail

# scaffold.sh — Creates the build-agent tutorial project.
#
# Usage: scaffold.sh <agent-name> <language> <provider> <track> [base-url] [model-name]
#
# Arguments:
#   agent-name  Display name for the agent (e.g., Marvin)
#   language    typescript | python | go | ruby
#   provider    gemini | openai | anthropic
#   track       guided | fast
#   base-url    (optional) OpenAI-compatible base URL
#   model-name  (optional) OpenAI-compatible model name

if [[ $# -lt 4 ]]; then
  echo "Usage: scaffold.sh <agent-name> <language> <provider> <track> [base-url] [model-name]" >&2
  exit 1
fi

AGENT_NAME="$1"
LANGUAGE="$2"
PROVIDER="$3"
TRACK="$4"
BASE_URL="${5:-}"
MODEL_NAME="${6:-}"

# Derive directory name (lowercase, spaces to hyphens)
AGENT_DIR="$(echo "$AGENT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"

# Validate language and set entry file / run command
case "$LANGUAGE" in
  typescript) ENTRY_FILE="agent.ts"; RUN_CMD="npx tsx agent.ts" ;;
  python)     ENTRY_FILE="agent.py"; RUN_CMD="python3 agent.py" ;;
  go)         ENTRY_FILE="main.go";  RUN_CMD="go run ." ;;
  ruby)       ENTRY_FILE="agent.rb"; RUN_CMD="ruby agent.rb" ;;
  *) echo "Unsupported language: $LANGUAGE" >&2; exit 1 ;;
esac

# Validate provider and set env var / key URL
case "$PROVIDER" in
  gemini)    ENV_VAR="GEMINI_API_KEY";    KEY_URL="https://aistudio.google.com/apikey" ;;
  openai)    ENV_VAR="OPENAI_API_KEY";    KEY_URL="https://platform.openai.com/api-keys" ;;
  anthropic) ENV_VAR="ANTHROPIC_API_KEY"; KEY_URL="https://console.anthropic.com/settings/keys" ;;
  *) echo "Unsupported provider: $PROVIDER" >&2; exit 1 ;;
esac

# Validate track
case "$TRACK" in
  guided|fast) ;;
  *) echo "Invalid track: $TRACK" >&2; exit 1 ;;
esac

ISO_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# --- Helpers ---

sed_inplace() {
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# --- Create project directory ---

mkdir -p "$AGENT_DIR"

if [[ -f "$AGENT_DIR/$ENTRY_FILE" ]]; then
  echo "Note: $AGENT_DIR/ already exists, files will be overwritten" >&2
fi

# --- Go: initialize module ---

if [[ "$LANGUAGE" == "go" ]]; then
  if [[ ! -f "$AGENT_DIR/go.mod" ]]; then
    # Prefer `go mod init` for the correct version, fall back to writing manually
    if (cd "$AGENT_DIR" && go mod init agent) 2>/dev/null; then
      : # success
    else
      cat << 'EOF' > "$AGENT_DIR/go.mod"
module agent

go 1.21
EOF
    fi
  fi
fi

# --- Write starter code ---
# Each language writes Part A (imports + .env loading + API key check),
# optional Part B (OpenAI extra vars), and Part C (stdin loop).
# Go uses two complete variants because OpenAI vars go inside loadEnv().

case "$LANGUAGE" in
  typescript)
    cat << 'PART_A' > "$AGENT_DIR/$ENTRY_FILE"
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
PART_A
    if [[ "$PROVIDER" == "openai" ]]; then
      cat << 'PART_B' >> "$AGENT_DIR/$ENTRY_FILE"

const BASE_URL = process.env.OPENAI_BASE_URL || "https://api.openai.com/v1";
const MODEL = process.env.MODEL_NAME || "gpt-4o";
PART_B
    fi
    cat << 'PART_C' >> "$AGENT_DIR/$ENTRY_FILE"

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
PART_C
    ;;

  python)
    cat << 'PART_A' > "$AGENT_DIR/$ENTRY_FILE"
import json
import os
from urllib.request import urlopen, Request

# Load .env file
with open(".env") as f:
    for line in f:
        if "=" in line:
            key, value = line.strip().split("=", 1)
            value = value.strip()
            if value and not value.startswith("#"):
                os.environ[key.strip()] = value

API_KEY = os.environ.get("GEMINI_API_KEY")
if not API_KEY:
    print("Missing GEMINI_API_KEY in .env file")
    exit(1)
PART_A
    if [[ "$PROVIDER" == "openai" ]]; then
      cat << 'PART_B' >> "$AGENT_DIR/$ENTRY_FILE"

BASE_URL = os.environ.get("OPENAI_BASE_URL", "https://api.openai.com/v1")
MODEL = os.environ.get("MODEL_NAME", "gpt-4o")
PART_B
    fi
    cat << 'PART_C' >> "$AGENT_DIR/$ENTRY_FILE"

def main():
    while True:
        try:
            user_input = input("> ")
        except (EOFError, KeyboardInterrupt):
            break
        # TODO: send to LLM API and print response

main()
PART_C
    ;;

  go)
    if [[ "$PROVIDER" == "openai" ]]; then
      cat << 'GO_OPENAI' > "$AGENT_DIR/$ENTRY_FILE"
package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

var (
	apiKey    string
	baseURL   string
	modelName string
)

func loadEnv() {
	data, err := os.ReadFile(".env")
	if err != nil {
		fmt.Fprintln(os.Stderr, "Could not read .env file:", err)
		os.Exit(1)
	}
	for _, line := range strings.Split(string(data), "\n") {
		if key, val, ok := strings.Cut(line, "="); ok {
			val = strings.TrimSpace(val)
			if val != "" && !strings.HasPrefix(val, "#") {
				os.Setenv(strings.TrimSpace(key), val)
			}
		}
	}
	apiKey = os.Getenv("OPENAI_API_KEY")
	if apiKey == "" {
		fmt.Fprintln(os.Stderr, "Missing OPENAI_API_KEY in .env file")
		os.Exit(1)
	}
	baseURL = os.Getenv("OPENAI_BASE_URL")
	if baseURL == "" {
		baseURL = "https://api.openai.com/v1"
	}
	modelName = os.Getenv("MODEL_NAME")
	if modelName == "" {
		modelName = "gpt-4o"
	}
}

func main() {
	loadEnv()
	scanner := bufio.NewScanner(os.Stdin)
	for {
		fmt.Print("> ")
		if !scanner.Scan() {
			break
		}
		input := scanner.Text()
		// TODO: send to LLM API and print response
		_ = input
	}
}
GO_OPENAI
    else
      cat << 'GO_DEFAULT' > "$AGENT_DIR/$ENTRY_FILE"
package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

var apiKey string

func loadEnv() {
	data, err := os.ReadFile(".env")
	if err != nil {
		fmt.Fprintln(os.Stderr, "Could not read .env file:", err)
		os.Exit(1)
	}
	for _, line := range strings.Split(string(data), "\n") {
		if key, val, ok := strings.Cut(line, "="); ok {
			val = strings.TrimSpace(val)
			if val != "" && !strings.HasPrefix(val, "#") {
				os.Setenv(strings.TrimSpace(key), val)
			}
		}
	}
	apiKey = os.Getenv("GEMINI_API_KEY")
	if apiKey == "" {
		fmt.Fprintln(os.Stderr, "Missing GEMINI_API_KEY in .env file")
		os.Exit(1)
	}
}

func main() {
	loadEnv()
	scanner := bufio.NewScanner(os.Stdin)
	for {
		fmt.Print("> ")
		if !scanner.Scan() {
			break
		}
		input := scanner.Text()
		// TODO: send to LLM API and print response
		_ = input
	}
}
GO_DEFAULT
    fi
    ;;

  ruby)
    cat << 'PART_A' > "$AGENT_DIR/$ENTRY_FILE"
require "net/http"
require "uri"
require "json"

# Load .env file
File.readlines(".env").each do |line|
  key, value = line.strip.split("=", 2)
  next unless key && value && !value.empty? && !value.start_with?("#")
  ENV[key.strip] = value.strip
end

API_KEY = ENV["GEMINI_API_KEY"]
abort("Missing GEMINI_API_KEY in .env file") unless API_KEY && !API_KEY.empty?
PART_A
    if [[ "$PROVIDER" == "openai" ]]; then
      cat << 'PART_B' >> "$AGENT_DIR/$ENTRY_FILE"

BASE_URL = ENV["OPENAI_BASE_URL"] || "https://api.openai.com/v1"
MODEL = ENV["MODEL_NAME"] || "gpt-4o"
PART_B
    fi
    cat << 'PART_C' >> "$AGENT_DIR/$ENTRY_FILE"

loop do
  print "> "
  input = gets
  break if input.nil?
  input = input.chomp
  # TODO: send to LLM API and print response
end
PART_C
    ;;
esac

# Substitute env var name for non-Gemini providers
# (Go+OpenAI already has the correct var baked in)
if [[ "$PROVIDER" != "gemini" ]]; then
  if [[ "$LANGUAGE" == "go" && "$PROVIDER" == "openai" ]]; then
    : # already correct
  else
    sed_inplace "s/GEMINI_API_KEY/$ENV_VAR/g" "$AGENT_DIR/$ENTRY_FILE"
  fi
fi

# --- Write .env ---

case "$PROVIDER" in
  gemini)
    cat << 'EOF' > "$AGENT_DIR/.env"
GEMINI_API_KEY=your-api-key-here
EOF
    ;;
  openai)
    if [[ -n "$BASE_URL" || -n "$MODEL_NAME" ]]; then
      cat > "$AGENT_DIR/.env" << COMPAT_EOF
OPENAI_API_KEY=your-api-key-here
OPENAI_BASE_URL=${BASE_URL:-https://api.openai.com/v1}
MODEL_NAME=${MODEL_NAME:-gpt-4o}
COMPAT_EOF
    else
      cat << 'EOF' > "$AGENT_DIR/.env"
OPENAI_API_KEY=your-api-key-here
# OPENAI_BASE_URL=https://api.openai.com/v1
# MODEL_NAME=gpt-4o
EOF
    fi
    ;;
  anthropic)
    cat << 'EOF' > "$AGENT_DIR/.env"
ANTHROPIC_API_KEY=your-api-key-here
EOF
    ;;
esac

# --- Write .gitignore ---

cat << 'EOF' > "$AGENT_DIR/.gitignore"
.env
.build-agent-progress
.claude/
EOF

if [[ "$LANGUAGE" == "typescript" ]]; then
  echo "node_modules/" >> "$AGENT_DIR/.gitignore"
fi

# --- Write AGENTS.md ---

cat > "$AGENT_DIR/AGENTS.md" << AGENTS_EOF
# $AGENT_NAME

$PROVIDER/$LANGUAGE coding agent built from scratch with raw HTTP calls.

## Setup
1. Add your API key to \`.env\`
2. Key URL: $KEY_URL

## Run
\`$RUN_CMD\`

## How it works
Agentic loop: prompt -> LLM -> tool call -> execute -> result back -> LLM -> ... -> text response

## Tools
- [ ] list_files
- [ ] read_file
- [ ] run_bash
- [ ] edit_file

## Structure
- \`$ENTRY_FILE\` -- main agent source
- \`.env\` -- API key (gitignored)
AGENTS_EOF

# --- Write .build-agent-progress ---

cat > "$AGENT_DIR/.build-agent-progress" << PROGRESS_EOF
agentName=$AGENT_NAME
language=$LANGUAGE
provider=$PROVIDER
PROGRESS_EOF

if [[ "$PROVIDER" == "openai" ]] && [[ -n "$BASE_URL" || -n "$MODEL_NAME" ]]; then
  cat >> "$AGENT_DIR/.build-agent-progress" << COMPAT_EOF
providerBaseUrl=${BASE_URL:-https://api.openai.com/v1}
providerModel=${MODEL_NAME:-gpt-4o}
COMPAT_EOF
fi

cat >> "$AGENT_DIR/.build-agent-progress" << PROGRESS_EOF
track=$TRACK
currentStep=1
completedSteps=
entryFile=$ENTRY_FILE
lastUpdated=$ISO_DATE
PROGRESS_EOF

# --- Summary ---

echo ""
echo "Created $AGENT_DIR/"
echo "  $ENTRY_FILE    ($LANGUAGE starter)"
echo "  .env        ($PROVIDER API key placeholder)"
echo "  .gitignore"
echo "  AGENTS.md"
echo "  .build-agent-progress"
if [[ "$LANGUAGE" == "go" ]]; then
  echo "  go.mod"
fi
echo ""
echo "Run: cd $AGENT_DIR && $RUN_CMD"
