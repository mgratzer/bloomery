# {{AGENT_NAME}}

{{PROVIDER}}/ruby coding agent built from scratch with raw HTTP calls.

## Setup
1. Add your API key to `.env`
2. Key URL: {{KEY_URL}}

## Run
`ruby agent.rb`

## How it works
Agentic loop: prompt -> LLM -> tool call -> execute -> result back -> LLM -> ... -> text response

## Tools
- [ ] list_files
- [ ] read_file
- [ ] run_bash
- [ ] edit_file

## Structure
- `agent.rb` -- main agent source
- `.env` -- API key (gitignored)
