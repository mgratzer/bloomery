#!/usr/bin/env bats

load helpers/common

# ── Argument validation (4 tests) ──────────────────────────────────────────────

@test "scaffold: missing arguments exits with error" {
  run_scaffold
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "invalid language exits with error" {
  run_scaffold TestAgent rust gemini guided
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unsupported language: rust"* ]]
}

@test "invalid provider exits with error" {
  run_scaffold TestAgent typescript azure guided
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unsupported provider: azure"* ]]
}

@test "invalid track exits with error" {
  run_scaffold TestAgent typescript gemini turbo
  [ "$status" -eq 1 ]
  [[ "$output" == *"Invalid track: turbo"* ]]
}

# ── File creation — one per language (4 tests) ────────────────────────────────

@test "typescript+gemini: creates expected files" {
  run_scaffold TestAgent typescript gemini guided
  [ "$status" -eq 0 ]
  [ -f testagent/agent.ts ]
  [ -f testagent/.env ]
  [ -f testagent/.gitignore ]
  [ -f testagent/AGENTS.md ]
  [ -f testagent/.build-agent-progress ]
  grep -q "node_modules/" testagent/.gitignore
}

@test "python+anthropic: creates expected files" {
  run_scaffold TestAgent python anthropic guided
  [ "$status" -eq 0 ]
  [ -f testagent/agent.py ]
  [ -f testagent/.env ]
  grep -q "ANTHROPIC_API_KEY" testagent/.env
}

@test "go+gemini: creates expected files" {
  run_scaffold TestAgent go gemini guided
  [ "$status" -eq 0 ]
  [ -f testagent/main.go ]
  [ -f testagent/.env ]
  [ -f testagent/.gitignore ]
  [ -f testagent/AGENTS.md ]
  [ -f testagent/.build-agent-progress ]
  [ -f testagent/go.mod ]
  grep -q "module agent" testagent/go.mod
}

@test "ruby+openai: creates expected files" {
  run_scaffold TestAgent ruby openai guided
  [ "$status" -eq 0 ]
  [ -f testagent/agent.rb ]
  [ -f testagent/.env ]
  grep -q "OPENAI_API_KEY" testagent/.env
}

# ── Env var substitution (3 tests) ────────────────────────────────────────────

@test "gemini keeps GEMINI_API_KEY in entry file" {
  run_scaffold TestAgent typescript gemini guided
  [ "$status" -eq 0 ]
  grep -q "GEMINI_API_KEY" testagent/agent.ts
}

@test "anthropic substitutes to ANTHROPIC_API_KEY" {
  run_scaffold TestAgent python anthropic guided
  [ "$status" -eq 0 ]
  grep -q "ANTHROPIC_API_KEY" testagent/agent.py
  ! grep -q "GEMINI_API_KEY" testagent/agent.py
}

@test "openai substitutes to OPENAI_API_KEY" {
  run_scaffold TestAgent ruby openai guided
  [ "$status" -eq 0 ]
  grep -q "OPENAI_API_KEY" testagent/agent.rb
  ! grep -q "GEMINI_API_KEY" testagent/agent.rb
}

# ── OpenAI compat mode (3 tests) ──────────────────────────────────────────────

@test "openai compat: base-url and model set in env and progress" {
  run_scaffold TestAgent typescript openai guided "https://custom.api/v1" "custom-model"
  [ "$status" -eq 0 ]
  grep -q "OPENAI_BASE_URL=https://custom.api/v1" testagent/.env
  grep -q "MODEL_NAME=custom-model" testagent/.env
  grep -q "providerBaseUrl=https://custom.api/v1" testagent/.build-agent-progress
  grep -q "providerModel=custom-model" testagent/.build-agent-progress
}

@test "openai compat: base-url only defaults MODEL_NAME to gpt-4o" {
  run_scaffold TestAgent typescript openai guided "https://custom.api/v1"
  [ "$status" -eq 0 ]
  grep -q "OPENAI_BASE_URL=https://custom.api/v1" testagent/.env
  grep -q "MODEL_NAME=gpt-4o" testagent/.env
}

@test "openai compat: without compat args has commented lines" {
  run_scaffold TestAgent typescript openai guided
  [ "$status" -eq 0 ]
  grep -q "^# OPENAI_BASE_URL=" testagent/.env
  grep -q "^# MODEL_NAME=" testagent/.env
  ! grep -q "providerBaseUrl" testagent/.build-agent-progress
}

# ── Go special cases (3 tests) ────────────────────────────────────────────────

@test "go+openai: uses dedicated template with baseURL and modelName" {
  run_scaffold TestAgent go openai guided
  [ "$status" -eq 0 ]
  grep -q "baseURL" testagent/main.go
  grep -q "modelName" testagent/main.go
}

@test "go+openai: skips sed substitution — no mangled content" {
  run_scaffold TestAgent go openai guided
  [ "$status" -eq 0 ]
  grep -q 'OPENAI_API_KEY' testagent/main.go
  ! grep -q 'GEMINI_API_KEY' testagent/main.go
  # Verify template structure is intact
  grep -q 'func loadEnv()' testagent/main.go
}

@test "go: falls back to manual go.mod without go on PATH" {
  # Restrict PATH to exclude go binary; keep coreutils for the script itself
  run bash -c 'PATH="/usr/bin:/bin" "$@" 2>&1' _ "$SKILL_DIR/scaffold.sh" TestAgent go gemini guided
  [ "$status" -eq 0 ]
  [ -f testagent/go.mod ]
  grep -q "module agent" testagent/go.mod
  grep -q "go 1.21" testagent/go.mod
}

# ── Directory name derivation (2 tests) ───────────────────────────────────────

@test "directory: uppercase converts to lowercase" {
  run_scaffold MyAgent typescript gemini guided
  [ "$status" -eq 0 ]
  [ -d myagent ]
  [ -f myagent/agent.ts ]
}

@test "directory: spaces convert to hyphens" {
  run_scaffold "My Cool Agent" typescript gemini guided
  [ "$status" -eq 0 ]
  [ -d my-cool-agent ]
  [ -f my-cool-agent/agent.ts ]
}

# ── AGENTS.md content (3 tests) ───────────────────────────────────────────────

@test "AGENTS.md: contains agent name as heading" {
  run_scaffold Marvin typescript gemini guided
  [ "$status" -eq 0 ]
  grep -q "^# Marvin" marvin/AGENTS.md
}

@test "AGENTS.md: has four unchecked tool checkboxes" {
  run_scaffold TestAgent typescript gemini guided
  [ "$status" -eq 0 ]
  local count
  count=$(grep -c '\- \[ \]' testagent/AGENTS.md)
  [ "$count" -eq 4 ]
}

@test "AGENTS.md: has correct run command for python" {
  run_scaffold TestAgent python gemini guided
  [ "$status" -eq 0 ]
  grep -q 'python3 agent.py' testagent/AGENTS.md
}

# ── Progress file (1 test) ────────────────────────────────────────────────────

@test "progress file: has correct initial fields" {
  run_scaffold TestAgent typescript gemini guided
  [ "$status" -eq 0 ]
  local pf="testagent/.build-agent-progress"
  grep -q "^agentName=TestAgent$"  "$pf"
  grep -q "^language=typescript$"  "$pf"
  grep -q "^provider=gemini$"      "$pf"
  grep -q "^track=guided$"         "$pf"
  grep -q "^currentStep=1$"        "$pf"
  grep -q "^completedSteps=$"      "$pf"
  grep -q "^entryFile=agent.ts$"   "$pf"
  # lastUpdated matches ISO 8601 pattern
  local ts
  ts=$(grep '^lastUpdated=' "$pf" | cut -d= -f2-)
  [[ "$ts" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

# ── Idempotency (1 test) ──────────────────────────────────────────────────────

@test "second scaffold run prints already-exists note" {
  run_scaffold TestAgent typescript gemini guided
  [ "$status" -eq 0 ]
  # Run again — the note goes to stderr, captured by the 2>&1 wrapper
  run_scaffold TestAgent typescript gemini guided
  [ "$status" -eq 0 ]
  [[ "$output" == *"already exists"* ]]
}
