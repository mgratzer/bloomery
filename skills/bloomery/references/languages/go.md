# Go Setup

## Runtime

Run with:
```bash
go run .
```

## Project Setup Commands

Run these Bash commands during Step 0 scaffold, in this order, before writing any files:

```bash
mkdir <agent-name>
cd <agent-name>   # or use the full path in subsequent commands
go mod init agent
```

`go mod init` creates the `go.mod` file that Go requires. Without it, `go run .` will fail with "go.mod file not found". This must be run as a Bash command — it cannot be replaced by a Write tool call.

## Standard Library Packages

All stdlib, no `go get` needed:

| Need | Import |
|------|--------|
| HTTP | `"net/http"` with `http.Post` or `http.NewRequest` |
| JSON | `"encoding/json"` with `json.Marshal` / `json.Unmarshal` |
| Stdin | `"bufio"`, `"os"` |
| Run commands | `"os/exec"` with `exec.Command` |
| Files | `"os"` (`os.ReadDir`, `os.ReadFile`, `os.WriteFile`) |

## Notes

Go users need to define structs for the request/response JSON. Suggest starting with a minimal struct and adding fields as needed. `map[string]any` works for quick prototyping but structs are better for tool definitions.

## Language Hints for Specific Steps

### Step 7 (Bash Tool): `exec.Command` returns an error on non-zero exit codes
Go's `exec.Command(...).CombinedOutput()` returns both the output bytes AND an error when the command exits non-zero. The output is still populated — don't discard it. Use `CombinedOutput()` (captures stdout+stderr together), check the error, and return the output string either way. Use `context.WithTimeout` for the timeout.

## Starter File

Write this as `main.go`. Replace `GEMINI_API_KEY` with the correct env var for the chosen provider (see Provider Env Vars in SKILL.md). For OpenAI, also add `baseURL` and `modelName` variables in `loadEnv()` with defaults from env or `"https://api.openai.com/v1"` / `"gpt-4o"`.

```go
package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

var apiKey string

func loadEnv() {
	data, err := os.ReadFile(".env")
	if err != nil {
		fmt.Fprintln(os.Stderr, "Could not read .env file:", err)
		os.Exit(1)
	}
	for _, line := range strings.Split(string(data), "\n") {
		if key, val, ok := strings.Cut(line, "="); ok {
			val = strings.TrimSpace(val)
			if val != "" && !strings.HasPrefix(val, "#") {
				os.Setenv(strings.TrimSpace(key), val)
			}
		}
	}
	apiKey = os.Getenv("GEMINI_API_KEY")
	if apiKey == "" {
		fmt.Fprintln(os.Stderr, "Missing GEMINI_API_KEY in .env file")
		os.Exit(1)
	}
}

func main() {
	loadEnv()
	scanner := bufio.NewScanner(os.Stdin)
	for {
		fmt.Print("> ")
		if !scanner.Scan() {
			break
		}
		input := scanner.Text()
		// TODO: send to LLM API and print response
		_ = input
	}
}
```
