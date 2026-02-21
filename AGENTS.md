# Bloomery Skill

An agent skill that teaches engineers how to build a coding agent from scratch using raw HTTP calls.

## Project Structure

```
skills/bloomery/
├── SKILL.md                           # Core skill logic (philosophy, rules, step dispatch)
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
README.md                              # User-facing docs, install instructions
LICENSE                                # MIT
```

## How It Works

At runtime, the agent loads SKILL.md + curriculum.md + one provider ref + one language ref (~1,100 lines). This keeps context efficient — the agent never loads all 2,300+ lines at once.

## Key Design Decisions

- **Coach, not generator**: The user writes all code. Escape hatch: they can ask the agent to implement a step, with confirmation.
- **Provider-agnostic curriculum**: Steps describe what to build; provider refs describe the wire format.
- **One file per provider/language**: Adding support = adding one file, no changes to SKILL.md or curriculum.
- **Auto-advance**: Agent moves to the next step immediately after validation passes.
- **Step 8 is optional**: edit_file is useful but doesn't teach new agent concepts.

## Contributing

To add a new provider: create `skills/bloomery/references/providers/<name>.md` following the structure of existing provider refs (auth, endpoints, request/response format, tool protocol, full round-trip example).

To add a new language: create `skills/bloomery/references/languages/<name>.md` with runtime setup, stdlib modules, and a starter code template.
