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

  # Collect +BLOCK flags (sections to keep) and KEY VALUE pairs
  local -a keep_blocks=()
  local -a pairs=()
  while [[ $# -gt 0 ]]; do
    if [[ "$1" == +* ]]; then
      keep_blocks+=("${1#+}")
      shift
    elif [[ $# -ge 2 ]]; then
      pairs+=("$1" "$2"); shift 2
    else
      shift
    fi
  done

  # Process {{#BLOCK}}...{{/BLOCK}} conditional sections in one awk pass:
  # kept blocks have markers stripped; unmatched blocks are removed entirely
  if [[ "$content" == *'{{#'* ]]; then
    local keep_csv=""
    for b in ${keep_blocks[@]+"${keep_blocks[@]}"}; do keep_csv="${keep_csv:+$keep_csv,}$b"; done
    content=$(printf '%s\n' "$content" | awk -v keeps="$keep_csv" '
      BEGIN { n = split(keeps, a, ","); for (i = 1; i <= n; i++) keep[a[i]] = 1 }
      /^\{\{#[A-Za-z_]+\}\}$/ {
        block = substr($0, 4, length($0) - 5)
        if (block in keep) next; skip = 1; next
      }
      /^\{\{\/[A-Za-z_]+\}\}$/ {
        block = substr($0, 4, length($0) - 5)
        if (block in keep) next; skip = 0; next
      }
      !skip
    ')
  fi

  # Simple {{KEY}} → value substitution
  local i=0
  while [[ $i -lt ${#pairs[@]} ]]; do
    local key="${pairs[$i]}" val="${pairs[$((i+1))]}"
    content="${content//\{\{${key}\}\}/${val}}"
    i=$((i + 2))
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

KEEP_BLOCKS=()
if [[ "$PROVIDER" == "openai" ]]; then
  KEEP_BLOCKS=(+OPENAI)
fi
apply_template "$TEMPLATE_DIR/$LANGUAGE/$ENTRY_FILE" \
  API_KEY_VAR "$ENV_VAR" \
  ${KEEP_BLOCKS[@]+"${KEEP_BLOCKS[@]}"} \
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

# --- Initialize git repo and commit initial scaffold ---

if command -v git &>/dev/null; then
  if (cd "$AGENT_DIR" && git init -q && git add -A && git commit -q -m "feat: scaffold $AGENT_NAME ($LANGUAGE/$PROVIDER)") 2>/dev/null; then
    GIT_INIT=true
  else
    GIT_INIT=false
  fi
else
  GIT_INIT=false
fi

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
if [[ "$GIT_INIT" == "true" ]]; then
  echo "  git repo initialized with initial commit"
fi
echo ""
echo "Run: cd $AGENT_DIR && $RUN_CMD"
