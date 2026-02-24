#!/usr/bin/env bats

load helpers/common

# ── Validation (2 tests) ──────────────────────────────────────────────────────

@test "progress-update: missing arguments exits with error" {
  run_progress_update
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "missing progress file exits with error" {
  mkdir -p nofile
  run_progress_update nofile 1
  [ "$status" -eq 1 ]
  [[ "$output" == *"not found"* ]]
}

# ── Step progression (4 tests) ────────────────────────────────────────────────

@test "first step: empty completedSteps gets first entry" {
  create_progress_fixture myagent
  run_progress_update myagent 1
  [ "$status" -eq 0 ]
  grep -q "^completedSteps=1$" myagent/.build-agent-progress
  grep -q "^currentStep=2$"    myagent/.build-agent-progress
}

@test "second step: appends with comma" {
  create_progress_fixture myagent
  "$SKILL_DIR/progress-update.sh" myagent 1
  run_progress_update myagent 2
  [ "$status" -eq 0 ]
  grep -q "^completedSteps=1,2$" myagent/.build-agent-progress
  grep -q "^currentStep=3$"      myagent/.build-agent-progress
}

@test "steps 1 through 3: currentStep=4 and completedSteps=1,2,3" {
  create_progress_fixture myagent
  "$SKILL_DIR/progress-update.sh" myagent 1
  "$SKILL_DIR/progress-update.sh" myagent 2
  run_progress_update myagent 3
  [ "$status" -eq 0 ]
  grep -q "^currentStep=4$"         myagent/.build-agent-progress
  grep -q "^completedSteps=1,2,3$"  myagent/.build-agent-progress
}

@test "lastUpdated changes and matches ISO 8601" {
  create_progress_fixture myagent
  run_progress_update myagent 1
  [ "$status" -eq 0 ]
  local updated
  updated=$(grep '^lastUpdated=' myagent/.build-agent-progress | cut -d= -f2-)
  # Must differ from the fixture's hardcoded value
  [ "$updated" != "2024-01-01T00:00:00Z" ]
  # Must match ISO 8601 pattern
  [[ "$updated" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

# ── AGENTS.md checkboxes (5 tests) ────────────────────────────────────────────

@test "step 5 ticks list_files checkbox" {
  create_progress_fixture myagent
  run_progress_update myagent 5
  [ "$status" -eq 0 ]
  grep -q '\- \[x\] list_files' myagent/AGENTS.md
  # Others remain unchecked
  grep -q '\- \[ \] read_file'  myagent/AGENTS.md
  grep -q '\- \[ \] run_bash'   myagent/AGENTS.md
  grep -q '\- \[ \] edit_file'  myagent/AGENTS.md
}

@test "step 6 ticks read_file checkbox" {
  create_progress_fixture myagent
  run_progress_update myagent 6
  [ "$status" -eq 0 ]
  grep -q '\- \[x\] read_file' myagent/AGENTS.md
}

@test "step 7 ticks run_bash checkbox" {
  create_progress_fixture myagent
  run_progress_update myagent 7
  [ "$status" -eq 0 ]
  grep -q '\- \[x\] run_bash' myagent/AGENTS.md
}

@test "step 8 ticks edit_file checkbox" {
  create_progress_fixture myagent
  run_progress_update myagent 8
  [ "$status" -eq 0 ]
  grep -q '\- \[x\] edit_file' myagent/AGENTS.md
}

@test "non-tool step leaves all checkboxes unchecked" {
  create_progress_fixture myagent
  run_progress_update myagent 3
  [ "$status" -eq 0 ]
  local count
  count=$(grep -c '\- \[ \]' myagent/AGENTS.md)
  [ "$count" -eq 4 ]
}

# ── Edge cases (2 tests) ──────────────────────────────────────────────────────

@test "missing AGENTS.md: progress file still updates without error" {
  create_progress_fixture myagent
  rm myagent/AGENTS.md
  run_progress_update myagent 5
  [ "$status" -eq 0 ]
  grep -q "^completedSteps=5$" myagent/.build-agent-progress
  grep -q "^currentStep=6$"    myagent/.build-agent-progress
}

@test "output message contains correct step numbers" {
  create_progress_fixture myagent
  run_progress_update myagent 1
  [ "$status" -eq 0 ]
  [[ "$output" == *"Step 1 complete"* ]]
  [[ "$output" == *"Step 2"* ]]
}

# ── Git commits (4 tests) ─────────────────────────────────────────────────────

@test "progress-update commits with conventional message for step 1" {
  command -v git >/dev/null || skip "git not available"
  create_progress_fixture myagent
  (cd myagent && git init -q && git add -A && git commit -q -m "feat: scaffold")
  # Simulate user adding code
  echo 'const chat = true;' >> myagent/AGENTS.md
  run_progress_update myagent 1
  [ "$status" -eq 0 ]
  local msg
  msg=$(cd myagent && git log --oneline -1 --format=%s)
  [[ "$msg" == "feat(step-1): basic chat REPL" ]]
}

@test "progress-update commits with conventional message for step 5" {
  command -v git >/dev/null || skip "git not available"
  create_progress_fixture myagent
  (cd myagent && git init -q && git add -A && git commit -q -m "feat: scaffold")
  echo 'const tools = true;' >> myagent/AGENTS.md
  run_progress_update myagent 5
  [ "$status" -eq 0 ]
  local msg
  msg=$(cd myagent && git log --oneline -1 --format=%s)
  [[ "$msg" == "feat(step-5): tool execution and agentic loop" ]]
}

@test "progress-update: no git repo does not error" {
  create_progress_fixture myagent
  run_progress_update myagent 1
  [ "$status" -eq 0 ]
  [[ "$output" == *"Step 1 complete"* ]]
  # No .git directory
  [ ! -d myagent/.git ]
}

@test "progress-update: full step sequence produces correct git log" {
  command -v git >/dev/null || skip "git not available"
  create_progress_fixture myagent
  (cd myagent && git init -q && git add -A && git commit -q -m "feat: scaffold")
  for step in 1 2 3; do
    echo "step $step code" >> myagent/AGENTS.md
    "$SKILL_DIR/progress-update.sh" myagent "$step"
  done
  local log
  log=$(cd myagent && git log --oneline --format=%s)
  [[ "$log" == *"feat(step-3): system prompt"* ]]
  [[ "$log" == *"feat(step-2): multi-turn conversation"* ]]
  [[ "$log" == *"feat(step-1): basic chat REPL"* ]]
}
