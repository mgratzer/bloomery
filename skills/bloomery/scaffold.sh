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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/templates"

apply_template() {
  local template_file="$1"; shift
  local content
  content="$(<"$template_file")"
  while [[ $# -ge 2 ]]; do
    local key="$1" val="$2"; shift 2
    content="${content//\{\{${key}\}\}/${val}}"
  done
  printf '%s\n' "$content"
}

# --- Create project directory ---

mkdir -p "$AGENT_DIR"

if [[ -f "$AGENT_DIR/$ENTRY_FILE" ]]; then
  echo "Note: $AGENT_DIR/ already exists, files will be overwritten" >&2
fi

# --- Go: initialize module ---

if [[ "$LANGUAGE" == "go" ]]; then
  if [[ ! -f "$AGENT_DIR/go.mod" ]]; then
    # Prefer `go mod init` for the correct version, fall back to template
    if (cd "$AGENT_DIR" && go mod init agent) 2>/dev/null; then
      : # success
    else
      cp "$TEMPLATE_DIR/go/go.mod" "$AGENT_DIR/go.mod"
    fi
  fi
fi

# --- Write starter code ---

if [[ "$PROVIDER" == "openai" ]]; then
  TEMPLATE_ENTRY="${ENTRY_FILE%.*}.openai.${ENTRY_FILE##*.}"
else
  TEMPLATE_ENTRY="$ENTRY_FILE"
fi
apply_template "$TEMPLATE_DIR/$LANGUAGE/$TEMPLATE_ENTRY" \
  API_KEY_VAR "$ENV_VAR" \
  > "$AGENT_DIR/$ENTRY_FILE"

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

cp "$TEMPLATE_DIR/$LANGUAGE/.gitignore" "$AGENT_DIR/.gitignore"

# --- Write AGENTS.md ---

apply_template "$TEMPLATE_DIR/$LANGUAGE/AGENTS.md" \
  AGENT_NAME "$AGENT_NAME" PROVIDER "$PROVIDER" KEY_URL "$KEY_URL" \
  > "$AGENT_DIR/AGENTS.md"

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
