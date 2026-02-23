#!/usr/bin/env bats

load helpers/common

# ═══════════════════════════════════════════════════════════════════════════════
# Layer 1 — Progress file (5 tests)
# ═══════════════════════════════════════════════════════════════════════════════

@test "layer 1: extracts basic fields as JSON" {
  create_progress_fixture myagent
  run_detect myagent
  [ "$status" -eq 0 ]
  [[ "$output" == *'"found": true'* ]]
  [[ "$output" == *'"source": "progress_file"'* ]]
  [[ "$output" == *'"agentName": "TestAgent"'* ]]
  [[ "$output" == *'"language": "typescript"'* ]]
  [[ "$output" == *'"provider": "gemini"'* ]]
  [[ "$output" == *'"track": "guided"'* ]]
  [[ "$output" == *'"currentStep": 1'* ]]
  [[ "$output" == *'"entryFile": "agent.ts"'* ]]
}

@test "layer 1: empty completedSteps yields empty JSON array" {
  create_progress_fixture myagent
  run_detect myagent
  [ "$status" -eq 0 ]
  [[ "$output" == *'"completedSteps": []'* ]]
}

@test "layer 1: non-empty completedSteps yields JSON array" {
  create_progress_fixture myagent
  # Advance through steps 1, 2, 3
  "$SKILL_DIR/progress-update.sh" myagent 1
  "$SKILL_DIR/progress-update.sh" myagent 2
  "$SKILL_DIR/progress-update.sh" myagent 3
  run_detect myagent
  [ "$status" -eq 0 ]
  [[ "$output" == *'"completedSteps": [1,2,3]'* ]]
}

@test "layer 1: OpenAI compat fields are not extracted" {
  mkdir -p myagent
  cat > myagent/.build-agent-progress << 'EOF'
agentName=TestAgent
language=typescript
provider=openai
providerBaseUrl=https://custom.api/v1
providerModel=custom-model
track=guided
currentStep=3
completedSteps=1,2
entryFile=agent.ts
lastUpdated=2024-01-01T00:00:00Z
EOF
  run_detect myagent
  [ "$status" -eq 0 ]
  [[ "$output" != *"providerBaseUrl"* ]]
  [[ "$output" != *"providerModel"* ]]
  [[ "$output" != *"custom.api"* ]]
}

@test "layer 1: explicit directory argument" {
  create_progress_fixture deep/nested/agent
  run_detect deep/nested/agent
  [ "$status" -eq 0 ]
  [[ "$output" == *'"found": true'* ]]
  [[ "$output" == *'"source": "progress_file"'* ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# Layer 2 — Code scan (21 tests)
# ═══════════════════════════════════════════════════════════════════════════════

# ── Entry file detection (6 tests) ────────────────────────────────────────────

@test "layer 2: empty directory yields found false" {
  mkdir -p emptydir
  run_detect emptydir
  [ "$status" -eq 0 ]
  [[ "$output" == '{"found": false}' ]]
}

@test "layer 2: detects agent.ts as typescript" {
  mkdir -p proj
  echo 'const x = 1;' > proj/agent.ts
  run_detect proj
  [ "$status" -eq 0 ]
  [[ "$output" == *'"language": "typescript"'* ]]
  [[ "$output" == *'"entryFile": "agent.ts"'* ]]
}

@test "layer 2: detects agent.py as python" {
  mkdir -p proj
  echo 'x = 1' > proj/agent.py
  run_detect proj
  [ "$status" -eq 0 ]
  [[ "$output" == *'"language": "python"'* ]]
  [[ "$output" == *'"entryFile": "agent.py"'* ]]
}

@test "layer 2: detects main.go as go" {
  mkdir -p proj
  echo 'package main' > proj/main.go
  run_detect proj
  [ "$status" -eq 0 ]
  [[ "$output" == *'"language": "go"'* ]]
  [[ "$output" == *'"entryFile": "main.go"'* ]]
}

@test "layer 2: detects agent.rb as ruby" {
  mkdir -p proj
  echo 'puts "hi"' > proj/agent.rb
  run_detect proj
  [ "$status" -eq 0 ]
  [[ "$output" == *'"language": "ruby"'* ]]
  [[ "$output" == *'"entryFile": "agent.rb"'* ]]
}

@test "layer 2: detects agent.js as typescript" {
  mkdir -p proj
  echo 'const x = 1;' > proj/agent.js
  run_detect proj
  [ "$status" -eq 0 ]
  [[ "$output" == *'"language": "typescript"'* ]]
  [[ "$output" == *'"entryFile": "agent.js"'* ]]
}

# ── Priority ──────────────────────────────────────────────────────────────────

@test "layer 2: agent.ts has priority over agent.py" {
  mkdir -p proj
  echo 'const x = 1;' > proj/agent.ts
  echo 'x = 1' > proj/agent.py
  run_detect proj
  [ "$status" -eq 0 ]
  [[ "$output" == *'"entryFile": "agent.ts"'* ]]
  [[ "$output" == *'"language": "typescript"'* ]]
}

# ── Provider detection (5 tests) ──────────────────────────────────────────────

@test "layer 2: detects gemini provider" {
  mkdir -p proj
  echo 'fetch("https://generativelanguage.googleapis.com/v1")' > proj/agent.ts
  run_detect proj
  [ "$status" -eq 0 ]
  [[ "$output" == *'"provider": "gemini"'* ]]
}

@test "layer 2: detects anthropic provider" {
  mkdir -p proj
  echo 'fetch("https://api.anthropic.com/v1/messages")' > proj/agent.ts
  run_detect proj
  [ "$status" -eq 0 ]
  [[ "$output" == *'"provider": "anthropic"'* ]]
}

@test "layer 2: detects openai provider by domain" {
  mkdir -p proj
  echo 'fetch("https://api.openai.com/v1/chat/completions")' > proj/agent.ts
  run_detect proj
  [ "$status" -eq 0 ]
  [[ "$output" == *'"provider": "openai"'* ]]
}

@test "layer 2: detects openai provider by chat/completions path" {
  mkdir -p proj
  echo 'fetch(baseUrl + "/chat/completions")' > proj/agent.ts
  run_detect proj
  [ "$status" -eq 0 ]
  [[ "$output" == *'"provider": "openai"'* ]]
}

@test "layer 2: unknown provider when no URL matches" {
  mkdir -p proj
  echo 'const x = 1;' > proj/agent.ts
  run_detect proj
  [ "$status" -eq 0 ]
  [[ "$output" == *'"provider": ""'* ]]
}

# ── Step detection (7 tests) ──────────────────────────────────────────────────

@test "layer 2: step 0 — no markers detected" {
  mkdir -p proj
  echo 'const x = 1;' > proj/agent.ts
  run_detect proj
  [ "$status" -eq 0 ]
  [[ "$output" == *'"detectedStep": 0'* ]]
}

@test "layer 2: step 1 — API URL detected" {
  mkdir -p proj
  cat > proj/agent.ts << 'EOF'
const url = "https://generativelanguage.googleapis.com/v1";
EOF
  run_detect proj
  [ "$status" -eq 0 ]
  [[ "$output" == *'"detectedStep": 1'* ]]
}

@test "layer 2: step 2 — messages with roles" {
  mkdir -p proj
  cat > proj/agent.ts << 'EOF'
const messages = [{ role: "user", content: "hello" }];
const contents = messages;
EOF
  run_detect proj
  [ "$status" -eq 0 ]
  [[ "$output" == *'"detectedStep": 2'* ]]
}

@test "layer 2: step 3 — system instruction" {
  mkdir -p proj
  cat > proj/agent.ts << 'EOF'
const messages = [{ role: "user", content: "hello" }];
const systemInstruction = "You are helpful";
EOF
  run_detect proj
  [ "$status" -eq 0 ]
  [[ "$output" == *'"detectedStep": 3'* ]]
}

@test "layer 2: step 4 — function declarations" {
  mkdir -p proj
  cat > proj/agent.ts << 'EOF'
const messages = [{ role: "user", content: "hello" }];
const systemInstruction = "You are helpful";
const functions = [{ name: "example_tool" }];
EOF
  run_detect proj
  [ "$status" -eq 0 ]
  [[ "$output" == *'"detectedStep": 4'* ]]
}

@test "layer 2: step 5 — tool dispatching" {
  mkdir -p proj
  cat > proj/agent.ts << 'EOF'
const messages = [{ role: "user", content: "hello" }];
const systemInstruction = "You are helpful";
const functions = [{ name: "list_files" }];
const result = response.tool_calls[0];
EOF
  run_detect proj
  [ "$status" -eq 0 ]
  [[ "$output" == *'"detectedStep": 5'* ]]
}

@test "layer 2: step 6 — read_file with readFile (TypeScript)" {
  mkdir -p proj
  cat > proj/agent.ts << 'EOF'
const messages = [{ role: "user", content: "hello" }];
const systemInstruction = "You are helpful";
const tools = [{ name: "list_files" }, { name: "read_file" }];
const result = response.tool_calls[0];
function handle_read_file(path) { return readFileSync(path); }
EOF
  run_detect proj
  [ "$status" -eq 0 ]
  [[ "$output" == *'"detectedStep": 6'* ]]
}

@test "layer 2: step 6 — read_file with open (Python)" {
  mkdir -p proj
  cat > proj/agent.py << 'EOF'
messages = [{"role": "user", "content": "hello"}]
system_prompt = "You are helpful"
tools = [{"name": "list_files"}, {"name": "read_file"}]
result = response["tool_calls"][0]
def handle_read_file(path):
    return open(path).read()
EOF
  run_detect proj
  [ "$status" -eq 0 ]
  [[ "$output" == *'"detectedStep": 6'* ]]
}

@test "layer 2: step 6 — read_file with ReadFile (Go)" {
  mkdir -p proj
  cat > proj/main.go << 'EOF'
package main
var messages = []Message{{Role: "user", Content: "hello"}}
var systemInstruction = "You are helpful"
var tools = []Tool{{Name: "list_files"}, {Name: "read_file"}}
result := response.FunctionCall
data, _ := os.ReadFile(path)
EOF
  run_detect proj
  [ "$status" -eq 0 ]
  [[ "$output" == *'"detectedStep": 6'* ]]
}

@test "layer 2: step 6 — read_file with File.read (Ruby)" {
  mkdir -p proj
  cat > proj/agent.rb << 'EOF'
messages = [{ role: "user", content: "hello" }]
system_prompt = "You are helpful"
tools = [{ name: "list_files" }, { name: "read_file" }]
result = response["tool_use"]
content = File.read(path)
EOF
  run_detect proj
  [ "$status" -eq 0 ]
  [[ "$output" == *'"detectedStep": 6'* ]]
}

@test "layer 2: step 7 — run_bash with child_process (TypeScript)" {
  mkdir -p proj
  cat > proj/agent.ts << 'EOF'
const messages = [{ role: "user", content: "hello" }];
const systemInstruction = "You are helpful";
const tools = [
  { name: "list_files" },
  { name: "read_file" },
  { name: "run_bash" }
];
const result = response.tool_calls[0];
function handle_read_file(path) { return readFileSync(path); }
function handle_run_bash(cmd) { return child_process.execSync(cmd); }
EOF
  run_detect proj
  [ "$status" -eq 0 ]
  [[ "$output" == *'"detectedStep": 7'* ]]
}

@test "layer 2: step 7 — run_bash with subprocess (Python)" {
  mkdir -p proj
  cat > proj/agent.py << 'EOF'
messages = [{"role": "user", "content": "hello"}]
system_prompt = "You are helpful"
tools = [{"name": "list_files"}, {"name": "read_file"}, {"name": "run_bash"}]
result = response["tool_calls"][0]
def handle_read_file(path):
    return open(path).read()
def handle_run_bash(cmd):
    return subprocess.run(cmd, capture_output=True)
EOF
  run_detect proj
  [ "$status" -eq 0 ]
  [[ "$output" == *'"detectedStep": 7'* ]]
}

@test "layer 2: step 7 — run_bash with os/exec (Go)" {
  mkdir -p proj
  cat > proj/main.go << 'EOF'
package main
import "os/exec"
var messages = []Message{{Role: "user", Content: "hello"}}
var systemInstruction = "You are helpful"
var tools = []Tool{{Name: "list_files"}, {Name: "read_file"}, {Name: "run_bash"}}
result := response.FunctionCall
data, _ := os.ReadFile(path)
out, _ := exec.Command(cmd).Output()
EOF
  run_detect proj
  [ "$status" -eq 0 ]
  [[ "$output" == *'"detectedStep": 7'* ]]
}

@test "layer 2: step 7 — run_bash with Open3 (Ruby)" {
  mkdir -p proj
  cat > proj/agent.rb << 'EOF'
messages = [{ role: "user", content: "hello" }]
system_prompt = "You are helpful"
tools = [{ name: "list_files" }, { name: "read_file" }, { name: "run_bash" }]
result = response["tool_use"]
content = File.read(path)
output = Open3.capture2(cmd)
EOF
  run_detect proj
  [ "$status" -eq 0 ]
  [[ "$output" == *'"detectedStep": 7'* ]]
}

@test "layer 2: step 8 — edit_file with old_string" {
  mkdir -p proj
  cat > proj/agent.ts << 'EOF'
const messages = [{ role: "user", content: "hello" }];
const systemInstruction = "You are helpful";
const tools = [
  { name: "list_files" },
  { name: "read_file" },
  { name: "run_bash" },
  { name: "edit_file" }
];
const result = response.tool_calls[0];
function handle_read_file() { readFile("test"); }
function handle_run_bash() { subprocess.run("ls"); }
function handle_edit_file(old_string, new_string) { return true; }
EOF
  run_detect proj
  [ "$status" -eq 0 ]
  [[ "$output" == *'"detectedStep": 8'* ]]
}

# ── Default directory & JSON validity (2 tests) ──────────────────────────────

@test "layer 2: default directory uses current directory" {
  echo 'const x = 1;' > agent.ts
  run_detect
  [ "$status" -eq 0 ]
  [[ "$output" == *'"found": true'* ]]
  [[ "$output" == *'"language": "typescript"'* ]]
}

@test "layer 2: output is valid JSON" {
  mkdir -p proj
  echo 'const x = 1;' > proj/agent.ts
  run_detect proj
  [ "$status" -eq 0 ]
  # Starts with { and ends with }
  [[ "$output" =~ ^\{ ]]
  [[ "$output" =~ \}$ ]]
  # Validate with jq if available
  if command -v jq &>/dev/null; then
    echo "$output" | jq . >/dev/null
  fi
}
