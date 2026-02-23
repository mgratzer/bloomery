# helpers/common.bash — Shared setup/teardown and fixture helpers for BATS tests.

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

setup() {
  TEST_TEMP_DIR="$(mktemp -d)"
  cd "$TEST_TEMP_DIR"
}

teardown() {
  rm -rf "$TEST_TEMP_DIR"
}

# Wrappers merge stderr into stdout so BATS $output captures error messages too.

run_scaffold() {
  run bash -c '"$@" 2>&1' _ "$SKILL_DIR/scaffold.sh" "$@"
}

run_progress_update() {
  run bash -c '"$@" 2>&1' _ "$SKILL_DIR/progress-update.sh" "$@"
}

run_detect() {
  run bash -c '"$@" 2>&1' _ "$SKILL_DIR/detect.sh" "$@"
}

# create_progress_fixture <dir>
# Writes a minimal .build-agent-progress + AGENTS.md with known values.
# Decouples progress-update tests from scaffold.sh correctness.
create_progress_fixture() {
  local dir="${1:?directory required}"

  mkdir -p "$dir"

  cat > "$dir/.build-agent-progress" << 'EOF'
agentName=TestAgent
language=typescript
provider=gemini
track=guided
currentStep=1
completedSteps=
entryFile=agent.ts
lastUpdated=2024-01-01T00:00:00Z
EOF

  cat > "$dir/AGENTS.md" << 'EOF'
# TestAgent

gemini/typescript coding agent built from scratch with raw HTTP calls.

## Tools
- [ ] list_files
- [ ] read_file
- [ ] run_bash
- [ ] edit_file
EOF
}
