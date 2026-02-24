#!/usr/bin/env bash
set -euo pipefail

# progress-update.sh — Atomically updates progress file + AGENTS.md after a validated step.
#
# Usage: progress-update.sh <agent-dir> <completed-step>
#
# What it does:
#   - Reads .build-agent-progress, increments currentStep, appends to completedSteps,
#     updates lastUpdated
#   - Ticks the matching AGENTS.md checkbox for tool steps (5=list_files, 6=read_file,
#     7=run_bash, 8=edit_file)

if [[ $# -lt 2 ]]; then
  echo "Usage: progress-update.sh <agent-dir> <completed-step>" >&2
  exit 1
fi

AGENT_DIR="$1"
COMPLETED_STEP="$2"
PROGRESS_FILE="$AGENT_DIR/.build-agent-progress"
AGENTS_FILE="$AGENT_DIR/AGENTS.md"

if [[ ! -f "$PROGRESS_FILE" ]]; then
  echo "Error: $PROGRESS_FILE not found" >&2
  exit 1
fi

ISO_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
NEXT_STEP=$((COMPLETED_STEP + 1))

# --- Cross-platform sed -i ---
sed_inplace() {
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# --- Update progress file ---

# Update currentStep
sed_inplace "s/^currentStep=.*/currentStep=$NEXT_STEP/" "$PROGRESS_FILE"

# Append to completedSteps
# Empty: completedSteps= -> completedSteps=N
# Non-empty: completedSteps=1,2 -> completedSteps=1,2,N
if grep -q '^completedSteps=$' "$PROGRESS_FILE"; then
  sed_inplace "s/^completedSteps=$/completedSteps=$COMPLETED_STEP/" "$PROGRESS_FILE"
else
  sed_inplace "s/^completedSteps=.*/&,$COMPLETED_STEP/" "$PROGRESS_FILE"
fi

# Update lastUpdated
sed_inplace "s/^lastUpdated=.*/lastUpdated=$ISO_DATE/" "$PROGRESS_FILE"

# --- Tick AGENTS.md checkbox ---

if [[ -f "$AGENTS_FILE" ]]; then
  case "$COMPLETED_STEP" in
    5) sed_inplace 's/- \[ \] list_files/- [x] list_files/' "$AGENTS_FILE" ;;
    6) sed_inplace 's/- \[ \] read_file/- [x] read_file/' "$AGENTS_FILE" ;;
    7) sed_inplace 's/- \[ \] run_bash/- [x] run_bash/' "$AGENTS_FILE" ;;
    8) sed_inplace 's/- \[ \] edit_file/- [x] edit_file/' "$AGENTS_FILE" ;;
  esac
fi

# --- Git commit for step progress ---

step_title() {
  case "$1" in
    1) echo "basic chat REPL" ;;
    2) echo "multi-turn conversation" ;;
    3) echo "system prompt" ;;
    4) echo "tool definition and detection" ;;
    5) echo "tool execution and agentic loop" ;;
    6) echo "read file tool" ;;
    7) echo "bash tool" ;;
    8) echo "edit file tool" ;;
    *) echo "step $1" ;;
  esac
}

if command -v git &>/dev/null; then
  AGENT_ABS=$(cd "$AGENT_DIR" && pwd -P)
  TOPLEVEL=$(git -C "$AGENT_DIR" rev-parse --show-toplevel 2>/dev/null) || true
  if [[ -n "$TOPLEVEL" && "$TOPLEVEL" == "$AGENT_ABS" ]]; then
    TITLE=$(step_title "$COMPLETED_STEP")
    (
      cd "$AGENT_DIR"
      git config --get user.name  >/dev/null 2>&1 || git config user.name  "Bloomery"
      git config --get user.email >/dev/null 2>&1 || git config user.email "bloomery@local"
      git add -A
      if ! git diff --cached --quiet 2>/dev/null; then
        git commit -q -m "feat(step-$COMPLETED_STEP): $TITLE"
      fi
    ) 2>/dev/null || true
  fi
fi

# --- Summary ---

echo "Step $COMPLETED_STEP complete → now on Step $NEXT_STEP"
