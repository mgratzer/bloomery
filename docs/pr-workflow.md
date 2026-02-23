# PR Workflow

## Commit Conventions

Format: `<type>(<scope>): <description>`

Types: feat, fix, docs, refactor, test, chore, perf

### Examples

```
feat(providers): add Groq provider reference
fix(scaffold): handle spaces in agent name
docs(curriculum): clarify step 5 validation criteria
test(detect): add edge case for empty source file
refactor(scaffold): extract placeholder substitution into function
```

### Scopes

Common scopes for this project:

| Scope | Used for |
|-------|----------|
| `providers` | Provider reference files (`references/providers/`) |
| `languages` | Language reference files (`references/languages/`) |
| `curriculum` | Curriculum changes (`references/curriculum.md`) |
| `scaffold` | Scaffolding script and templates |
| `detect` | Progress detection script |
| `skill` | SKILL.md changes |
| `ci` | GitHub Actions workflow |

Scope is optional — omit it for changes that span multiple areas.

## Branch Naming

Format: `<type>/<short-kebab-description>`

### Examples

```
feat/add-groq-provider
fix/scaffold-spaces-in-name
docs/improve-step-5-hints
test/detect-edge-cases
```

## PR Checklist

- [ ] Code follows project guidelines (see [Coding Guidelines](coding-guidelines.md))
- [ ] Shell scripts work on bash 3.2+ (no bash 4+ features)
- [ ] Tests added/updated (see [Testing](testing.md))
- [ ] All BATS tests pass: `bats skills/bloomery/tests/`
- [ ] Tests pass on both Linux and macOS (CI checks this)
- [ ] Documentation updated if applicable
- [ ] CHANGELOG.md updated for user-facing changes
- [ ] Commit messages follow conventional commit format

## Review Process

1. Open a PR with a clear title (conventional commit format)
2. CI runs BATS tests on Ubuntu + macOS
3. Review focuses on:
   - Shell compatibility (bash 3.2+, BSD vs GNU tools)
   - Curriculum clarity (is the teaching effective?)
   - Provider accuracy (do API examples match current docs?)
4. Squash-merge to main
