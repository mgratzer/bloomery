# Architecture

Bloomery is an agent skill — a structured prompt + reference files that a coding agent loads at runtime to teach users how to build their own coding agent from scratch.

The project contains no application code. It's composed of **shell scripts** (scaffolding, detection, progress tracking), **markdown references** (curriculum, provider APIs, language guides), and **templates** (starter projects in four languages).

## Project Structure

```
skills/bloomery/
├── SKILL.md                        # Core skill logic: philosophy, rules, step dispatch
├── scaffold.sh                     # Creates the user's starter project from templates
├── detect.sh                       # Determines which curriculum step the user is on
├── progress-update.sh              # Updates the user's progress file
├── templates/                      # Standalone starter projects per language
│   ├── typescript/                 # agent.ts, .gitignore, AGENTS.md
│   ├── python/                     # agent.py, .gitignore, AGENTS.md
│   ├── go/                         # main.go, go.mod, .gitignore, AGENTS.md
│   └── ruby/                       # agent.rb, .gitignore, AGENTS.md
├── references/
│   ├── curriculum.md               # 8-step curriculum (provider-agnostic)
│   ├── providers/
│   │   ├── gemini.md               # Gemini API wire format, auth, examples
│   │   ├── openai.md               # OpenAI (+ compatible) wire format, auth
│   │   └── anthropic.md            # Anthropic wire format, auth, examples
│   └── languages/
│       ├── typescript.md           # TS runtime, stdlib, starter code
│       ├── python.md               # Python runtime, stdlib, starter code
│       ├── go.md                   # Go runtime, stdlib, starter code
│       └── ruby.md                 # Ruby runtime, stdlib, starter code
└── tests/                          # BATS test suite
    ├── helpers/common.bash         # Shared setup/teardown and fixture helpers
    ├── scaffold.bats               # 25 tests for scaffold.sh
    ├── detect.bats                 # 34 tests for detect.sh
    └── progress-update.bats        # 13 tests for progress-update.sh
```

## Data Flow

### Runtime Context Loading

When a user invokes the skill, the hosting agent loads files in a specific order to keep context efficient (~1,100 lines instead of all 2,300+):

```
User invokes skill
  → Agent reads SKILL.md (philosophy, rules, step dispatch)
  → User picks provider + language
  → Agent reads references/providers/<provider>.md
  → Agent reads references/languages/<language>.md
  → Agent reads references/curriculum.md
  → Tutorial begins at detected step
```

### Scaffolding Flow

```
scaffold.sh <language> <agent-name> <provider> <directory>
  → Copies templates/<language>/* into <directory>
  → Substitutes placeholders (__AGENT_NAME__, etc.) in copied files
  → Creates .env file with provider-specific env var stub
```

### Progress Detection Flow

```
detect.sh <directory> <provider> <language>
  → Reads the user's source file
  → Checks for patterns indicating each step's completion
  → Outputs the current step number (1–8)
```

## Module Responsibilities

| Module | Purpose |
|--------|---------|
| `SKILL.md` | Defines the agent's behavior: coaching philosophy, hint escalation, context loading, step dispatch |
| `curriculum.md` | Provider-agnostic curriculum — what to build at each step, validation criteria |
| `providers/*.md` | Wire format for each LLM API: endpoints, auth, request/response structure, tool call protocol |
| `languages/*.md` | Language-specific guidance: runtime setup, stdlib modules, idiomatic patterns |
| `templates/` | Starter projects — boilerplate stdin loop, imports, config, so users jump straight to the interesting part |
| `scaffold.sh` | Copies templates and performs placeholder substitution |
| `detect.sh` | Pattern-matches user code to determine current curriculum step |
| `progress-update.sh` | Writes/updates the progress tracking file |
| `tests/` | BATS test suite covering all three shell scripts |
