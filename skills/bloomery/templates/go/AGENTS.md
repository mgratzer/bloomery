# {{AGENT_NAME}}

{{PROVIDER}}/go coding agent built from scratch with raw HTTP calls.

## Setup
1. Add your API key to `.env`
2. Key URL: {{KEY_URL}}

## Run
`go run .`

## How it works
Agentic loop: prompt -> LLM -> tool call -> execute -> result back -> LLM -> ... -> text response

## Tools
- [ ] list_files
- [ ] read_file
- [ ] run_bash
- [ ] edit_file

## Structure
- `main.go` -- main agent source
- `.env` -- API key (gitignored)
