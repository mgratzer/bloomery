# Bloomery

<p align="center">
  <strong>The best way to understand how agents work is to build one.</strong><br>
  ~300 lines. No frameworks. Easier than you think.
</p>

---

A bloomery is where raw ore becomes iron for the first time. Crude, but real. You understand it differently once you've made it yourself.

You're already inside one. That agent is going to guide you to build one from scratch. Raw HTTP calls, no SDKs, eight steps. When you write the agentic loop yourself, something clicks that no article ever gave you.

---

## What you'll build

A working coding agent in ~300 lines of code. No frameworks, no SDKs. Just raw HTTP calls to your LLM of choice. By the end, your agent will have:

- A conversational interface with multi-turn memory
- A system prompt that gives it identity and purpose
- Four tools: list files, read files, run shell commands, edit files
- An agentic loop that keeps calling the API until the model stops requesting tools

## Prerequisites

- A coding agent that supports the [Agent Skills](https://agentskills.io) standard (see [Install](#install) below)
- An API key for your chosen LLM provider (see below)
- Your language of choice (TypeScript, Python, Go, Ruby, or anything that can do HTTP + JSON)

### Supported LLM Providers

Pick whichever LLM API you want to build against:

| Provider | Model | Free tier | Get a key |
|----------|-------|-----------|-----------|
| **Google Gemini** | `gemini-2.5-flash` | ✅ Yes | [aistudio.google.com/apikey](https://aistudio.google.com/apikey) |
| **OpenAI** | `gpt-4o` | ❌ Paid | [platform.openai.com/api-keys](https://platform.openai.com/api-keys) |
| **OpenAI-compatible** | Any | Varies | Ollama (local/free), Together AI, Groq, LM Studio, etc. |
| **Anthropic** | `claude-sonnet-4-6` | ❌ Paid | [console.anthropic.com](https://console.anthropic.com/settings/keys) |

The tutorial adapts to your provider. The concepts are the same, only the wire format differs.

## Install

This skill works with any coding agent that supports the [Agent Skills](https://agentskills.io) standard. The installer will ask you which agent you use and set everything up:

```bash
npx skills add mgratzer/bloomery
```

Then open your agent and invoke the skill (usually `/bloomery` or `$bloomery` depending on your agent).

> **⚠️ GitHub Copilot CLI:** The Copilot CLI did not reliably follow the skill's structured instructions in our tests. It tends to improvise its own project setup instead of using the provided scaffold. If you have a Copilot subscription, use **VS Code with GitHub Copilot** instead, which works correctly.

> **Note:** Different models can produce different output. We've tested with the latest models from Anthropic, OpenAI, and Google, all work well. Agents tested: Claude Code, Codex CLI, Gemini CLI, Pi, VS Code with GitHub Copilot, and OpenCode.

## Usage

The skill will:

1. Ask you to pick an LLM provider (Gemini, OpenAI/compatible, or Anthropic), your language, name your agent, and pick a track (Guided ~60-90min or Fast Track ~30-45min)
2. Scaffold the starter project for you (boilerplate stdin loop, `.env` file, imports, the boring stuff)
3. Walk you through 8 incremental steps, validating your code at each one
4. Surface "meta moments" connecting what you're building to how the agent you're using works

## Curriculum

| Step | What you build | Key concept |
|------|---------------|-------------|
| 1 | Basic chat REPL | HTTP POST, response parsing, stdin loop |
| 2 | Multi-turn conversation | Message accumulation, conversation history |
| 3 | System prompt | Agent identity, proactive tool use |
| 4 | Tool definition & detection | Declaring tools, detecting tool calls in responses |
| 5 | Tool execution & agentic loop | Executing tools, sending results, the agent loop |
| 6 | Read File tool | Tool dispatcher pattern |
| 7 | Bash tool | Subprocess execution, timeouts |
| 8 | Edit File tool (optional) | File creation and find-and-replace |

## Philosophy

By default, the skill coaches you. It doesn't write code for you. It uses a 4-level hint system:

1. Conceptual nudge
2. Structural hint
3. Pseudocode
4. Small snippet (last resort)

If you're stuck or just want to move on, ask the agent to implement a step for you. It'll confirm first, then do it. Some people learn by reading code too.

## Credits

Based on [Jeff Huntley's agent workshop](https://ghuntley.com/agent).
