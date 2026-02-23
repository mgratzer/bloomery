# Bloomery Skill

An agent skill that teaches engineers how to build a coding agent from scratch using raw HTTP calls.

## Project Structure

```
skills/bloomery/
├── SKILL.md                           # Core skill logic (philosophy, rules, step dispatch)
├── scaffold.sh                        # Project scaffolding (copies templates, substitutes placeholders)
├── detect.sh                          # Progress detection (which step the user is on)
├── progress-update.sh                 # Progress file updates
├── templates/                         # Standalone scaffold templates per language
│   ├── typescript/                    # agent.ts, .gitignore, AGENTS.md
│   ├── python/                        # agent.py, .gitignore, AGENTS.md
│   ├── go/                            # main.go, go.mod, .gitignore, AGENTS.md
│   └── ruby/                          # agent.rb, .gitignore, AGENTS.md
├── references/
│   ├── curriculum.md                  # 8-step curriculum (provider-agnostic)
│   ├── providers/
│   │   ├── gemini.md                  # Gemini API wire format, auth, examples
│   │   ├── openai.md                  # OpenAI (+ compatible) wire format, auth, examples
│   │   └── anthropic.md              # Anthropic wire format, auth, examples
│   └── languages/
│       ├── typescript.md              # TS runtime, stdlib, starter code
│       ├── python.md                  # Python runtime, stdlib, starter code
│       ├── go.md                      # Go runtime, stdlib, starter code
│       └── ruby.md                    # Ruby runtime, stdlib, starter code
├── tests/                             # BATS test suite (scaffold, detect, progress-update)
│   ├── helpers/common.bash            # Shared setup/teardown and fixture helpers
│   ├── scaffold.bats                  # 24 tests for scaffold.sh
│   ├── detect.bats                    # 34 tests for detect.sh
│   └── progress-update.bats          # 13 tests for progress-update.sh
AGENTS.md                              # Agent instructions for contributing
README.md                              # User-facing docs, install instructions
LICENSE                                # MIT
```

## Documentation

| Document | Purpose |
|----------|---------|
| [Architecture](docs/architecture.md) | System design, data flow, module responsibilities |
| [Development](docs/development.md) | Prerequisites, setup, daily workflow |
| [Coding Guidelines](docs/coding-guidelines.md) | Shell script conventions, naming, markdown style |
| [Testing](docs/testing.md) | BATS test commands, conventions, CI matrix |
| [PR Workflow](docs/pr-workflow.md) | Commits, branch naming, PR checklist |

## How It Works

At runtime, the agent loads SKILL.md + curriculum.md + one provider ref + one language ref (~1,100 lines). This keeps context efficient as the agent never loads all 2,300+ lines at once.

## Key Design Decisions

- **Coach, not generator**: The user writes all code. Escape hatch: they can ask the agent to implement a step, with confirmation.
- **Provider-agnostic curriculum**: Steps describe what to build; provider refs describe the wire format.
- **One file per provider/language**: Adding support = adding one file, no changes to SKILL.md or curriculum.
- **Auto-advance**: Agent moves to the next step immediately after validation passes.
- **Step 8 is optional**: edit_file is useful but doesn't teach new agent concepts.

## Commits and PRs

Use [Conventional Commits](https://www.conventionalcommits.org/) for commit messages and PR titles (e.g. `feat: add Ruby provider`, `fix: correct env var name`, `docs: simplify install instructions`, `chore: update dependencies`).

## Contributing

To add a new provider: create `skills/bloomery/references/providers/<name>.md` following the structure of existing provider refs (auth, endpoints, request/response format, tool protocol, full round-trip example).

To add a new language: create `skills/bloomery/references/languages/<name>.md` with runtime setup, stdlib modules, and a starter code template.
