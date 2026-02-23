# Coding Guidelines

## Shell Scripts

All tooling scripts (`scaffold.sh`, `detect.sh`, `progress-update.sh`) must:

- Start with `#!/usr/bin/env bash`
- Work on **bash 3.2+** (macOS ships with 3.2; avoid bash 4+ features like associative arrays, `${var,,}`, `mapfile`)
- Use `set -euo pipefail` for strict error handling
- Quote all variable expansions: `"$var"`, not `$var`
- Use `[[ ]]` for conditionals, not `[ ]`

### Naming Conventions

- **Shell scripts**: `kebab-case.sh` (e.g., `progress-update.sh`)
- **Shell functions**: `snake_case` (e.g., `detect_step`)
- **Shell variables**: `UPPER_SNAKE_CASE` for constants, `lower_snake_case` for locals
- **Template placeholders**: `__UPPER_SNAKE_CASE__` (e.g., `__AGENT_NAME__`, `__PROVIDER__`)

## Markdown Reference Files

- **Provider references** (`references/providers/*.md`): Follow the structure of existing provider refs — auth, endpoints, request/response format, tool protocol, full round-trip example.
- **Language references** (`references/languages/*.md`): Runtime setup, stdlib modules, and starter code.
- **Curriculum** (`references/curriculum.md`): Provider-agnostic step descriptions with validation criteria.

### Writing Style

- Be specific and concrete — show exact JSON structures, exact extraction paths
- Use code blocks with language hints for all code examples
- Keep provider-specific details in provider files, not in the curriculum

## Templates

Each template directory (`templates/<language>/`) contains a complete starter project:

- Entry file with a boilerplate stdin loop and `// TODO` marker
- `.gitignore` appropriate for the language
- `AGENTS.md` with agent instructions for the scaffolded project

Templates use placeholder substitution. Available placeholders:

| Placeholder | Replaced with |
|-------------|--------------|
| `__AGENT_NAME__` | User's chosen agent name |
| `__PROVIDER__` | LLM provider name |
| `__MODEL__` | Default model for the provider |
| `__ENV_VAR__` | Environment variable name for the API key |

## Error Handling

- Shell scripts should fail fast (`set -e`) and surface clear error messages
- Validate inputs at the top of each script (check required arguments, verify files exist)
- Use `echo "Error: ..." >&2` for error messages (stderr, not stdout)

## Documentation

- Add comments to shell scripts only where the logic isn't self-evident
- Reference files are self-documenting — they *are* the documentation
- Use `<!-- TODO: ... -->` in markdown for sections that need filling in
