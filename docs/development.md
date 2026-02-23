# Development

## Prerequisites

- **Bash** 3.2+ (ships with macOS; available on all Linux distros)
- **BATS** (Bash Automated Testing System) — for running the test suite
- **Git** — for version control and CI

### Installing BATS

macOS:
```bash
brew install bats-core
```

Ubuntu/Debian:
```bash
sudo apt-get install bats
```

## Setup

```bash
git clone https://github.com/mgratzer/bloomery.git
cd bloomery
```

No dependencies to install — the project is pure bash and markdown.

## Daily Workflow

1. **Edit** shell scripts in `skills/bloomery/` or reference/template files
2. **Test** your changes:
   ```bash
   bats skills/bloomery/tests/
   ```
3. **Test a specific script**:
   ```bash
   bats skills/bloomery/tests/scaffold.bats
   bats skills/bloomery/tests/detect.bats
   bats skills/bloomery/tests/progress-update.bats
   ```
4. **Commit** using conventional commit format

## Available Commands

| Command | What it does |
|---------|-------------|
| `bats skills/bloomery/tests/` | Run the full BATS test suite (63 tests) |
| `bats skills/bloomery/tests/scaffold.bats` | Run scaffold.sh tests (24 tests) |
| `bats skills/bloomery/tests/detect.bats` | Run detect.sh tests (26 tests) |
| `bats skills/bloomery/tests/progress-update.bats` | Run progress-update.sh tests (13 tests) |

## Manual Testing

To test the skill end-to-end, install it into a coding agent:

```bash
npx skills add mgratzer/bloomery
```

Then invoke it from the agent (e.g., `/bloomery` in Claude Code) and walk through the curriculum steps.
