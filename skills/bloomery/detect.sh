#!/usr/bin/env bash
set -euo pipefail

# detect.sh — Detects tutorial progress for session resume.
#
# Usage: detect.sh [directory]
#
# Layer 1: If .build-agent-progress exists, outputs its fields as JSON.
# Layer 2: If no progress file, scans source files to detect language/provider/step.
# Output: Single JSON line to stdout.

DIR="${1:-.}"
PROGRESS_FILE="$DIR/.build-agent-progress"

# --- Layer 1: Progress file ---

if [[ -f "$PROGRESS_FILE" ]]; then
  AGENT_NAME=$(grep '^agentName=' "$PROGRESS_FILE" | cut -d= -f2-)
  LANGUAGE=$(grep '^language=' "$PROGRESS_FILE" | cut -d= -f2-)
  PROVIDER=$(grep '^provider=' "$PROGRESS_FILE" | cut -d= -f2-)
  TRACK=$(grep '^track=' "$PROGRESS_FILE" | cut -d= -f2-)
  CURRENT_STEP=$(grep '^currentStep=' "$PROGRESS_FILE" | cut -d= -f2-)
  COMPLETED_STEPS=$(grep '^completedSteps=' "$PROGRESS_FILE" | cut -d= -f2-)
  ENTRY_FILE=$(grep '^entryFile=' "$PROGRESS_FILE" | cut -d= -f2-)

  # Convert comma-separated completedSteps to JSON array
  if [[ -z "$COMPLETED_STEPS" ]]; then
    COMPLETED_JSON="[]"
  else
    COMPLETED_JSON="[${COMPLETED_STEPS}]"
  fi

  echo "{\"found\": true, \"source\": \"progress_file\", \"agentName\": \"$AGENT_NAME\", \"language\": \"$LANGUAGE\", \"provider\": \"$PROVIDER\", \"track\": \"$TRACK\", \"currentStep\": $CURRENT_STEP, \"completedSteps\": $COMPLETED_JSON, \"entryFile\": \"$ENTRY_FILE\"}"
  exit 0
fi

# --- Layer 2: Code scanning fallback ---

# Find the entry file
ENTRY_FILE=""
LANGUAGE=""
for pattern in agent.ts agent.py main.go agent.rb agent.js; do
  if [[ -f "$DIR/$pattern" ]]; then
    ENTRY_FILE="$pattern"
    case "$pattern" in
      *.ts) LANGUAGE="typescript" ;;
      *.py) LANGUAGE="python" ;;
      *.go) LANGUAGE="go" ;;
      *.rb) LANGUAGE="ruby" ;;
      *.js) LANGUAGE="typescript" ;;
    esac
    break
  fi
done

if [[ -z "$ENTRY_FILE" ]]; then
  echo '{"found": false}'
  exit 0
fi

SOURCE_FILE="$DIR/$ENTRY_FILE"

# Detect provider by API URL patterns
PROVIDER=""
if grep -q "generativelanguage.googleapis.com" "$SOURCE_FILE" 2>/dev/null; then
  PROVIDER="gemini"
elif grep -q "api.anthropic.com" "$SOURCE_FILE" 2>/dev/null; then
  PROVIDER="anthropic"
elif grep -q "openai.com\|chat/completions" "$SOURCE_FILE" 2>/dev/null; then
  PROVIDER="openai"
fi

# Detect step by checking markers in reverse order (highest first)
DETECTED_STEP=0
if grep -q "edit_file" "$SOURCE_FILE" && grep -q "old_string\|new_string" "$SOURCE_FILE"; then
  DETECTED_STEP=8
elif grep -q "run_bash" "$SOURCE_FILE" && grep -qi "exec\|spawn\|child_process\|subprocess\|os/exec\|Open3" "$SOURCE_FILE"; then
  DETECTED_STEP=7
elif grep -q "read_file" "$SOURCE_FILE" && grep -qi "readFileSync\|readFile\|ReadFile\|os\.ReadFile\|File\.read\|open(" "$SOURCE_FILE"; then
  DETECTED_STEP=6
elif grep -q "list_files" "$SOURCE_FILE" && grep -qi "functionCall\|tool_calls\|tool_use" "$SOURCE_FILE"; then
  DETECTED_STEP=5
elif grep -q "list_files\|tools\|functionDeclaration\|functions" "$SOURCE_FILE"; then
  DETECTED_STEP=4
elif grep -qi "systemInstruction\|system.*prompt\|role.*system" "$SOURCE_FILE"; then
  DETECTED_STEP=3
elif grep -qi "messages\|contents" "$SOURCE_FILE" && grep -qi "role.*user\|role.*model\|role.*assistant" "$SOURCE_FILE"; then
  DETECTED_STEP=2
elif grep -qi "generativelanguage\|api\.openai\|api\.anthropic\|chat/completions" "$SOURCE_FILE"; then
  DETECTED_STEP=1
fi

echo "{\"found\": true, \"source\": \"code_scan\", \"language\": \"$LANGUAGE\", \"provider\": \"$PROVIDER\", \"entryFile\": \"$ENTRY_FILE\", \"detectedStep\": $DETECTED_STEP}"
