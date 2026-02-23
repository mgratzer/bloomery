# Testing

## Running Tests

Run the full test suite:
```bash
bats skills/bloomery/tests/
```

Run tests for a specific script:
```bash
bats skills/bloomery/tests/scaffold.bats
bats skills/bloomery/tests/detect.bats
bats skills/bloomery/tests/progress-update.bats
```

## Test Framework

The project uses [BATS](https://github.com/bats-core/bats-core) (Bash Automated Testing System). BATS tests are plain bash scripts with a simple structure:

```bash
@test "description of what this tests" {
  run some_command --with args
  [ "$status" -eq 0 ]
  [[ "$output" == *"expected text"* ]]
}
```

## Test Conventions

- **Test location**: `skills/bloomery/tests/` — one `.bats` file per shell script
- **Naming**: Test file matches the script it tests (`scaffold.bats` tests `scaffold.sh`)
- **Helpers**: Shared setup/teardown lives in `tests/helpers/common.bash`
- **Temp directories**: Tests create temporary directories for isolation; helpers handle cleanup

### Test File Structure

Each `.bats` file:
1. Sources `helpers/common.bash` for shared setup/teardown
2. Groups tests by feature area using comment headers
3. Uses `setup` and `teardown` functions for per-test isolation

## Current Test Coverage

| Script | Tests | File |
|--------|-------|------|
| `scaffold.sh` | 24 | `tests/scaffold.bats` |
| `detect.sh` | 26 | `tests/detect.bats` |
| `progress-update.sh` | 13 | `tests/progress-update.bats` |
| **Total** | **63** | |

## CI

Tests run automatically on push and PR via GitHub Actions (`.github/workflows/bloomery-tests.yml`). The CI matrix tests on both **Ubuntu** and **macOS** to ensure cross-platform compatibility — this is critical because the shell scripts must work with both GNU and BSD tooling.

## Writing Tests

When adding a new test:

1. Add it to the appropriate `.bats` file
2. Use the helpers from `common.bash` for setup/teardown
3. Test both success and failure cases
4. Test edge cases (empty input, missing files, special characters)
5. Run the full suite to check for regressions: `bats skills/bloomery/tests/`
