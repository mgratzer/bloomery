# OpenAI API Reference (Raw HTTP)

Quick reference for making raw HTTP calls to the OpenAI Chat Completions API. No SDK required — just HTTP POST with JSON.

This reference also covers **OpenAI-compatible endpoints** (Ollama, Together AI, Groq, Azure OpenAI, LM Studio, vLLM, etc.) — same wire format, different base URL.

## Endpoint

```
POST https://api.openai.com/v1/chat/completions
```

**Default model:** `gpt-4o`

### OpenAI-Compatible Endpoints

Any service that implements the OpenAI Chat Completions API works with the same code. Just change the base URL and model name:

| Provider | Base URL | Example model |
|----------|----------|---------------|
| OpenAI | `https://api.openai.com/v1` | `gpt-4o` |
| Ollama (local) | `http://localhost:11434/v1` | `llama3.1` |
| Together AI | `https://api.together.xyz/v1` | `meta-llama/Llama-3.1-70B-Instruct-Turbo` |
| Groq | `https://api.groq.com/openai/v1` | `llama-3.3-70b-versatile` |
| LM Studio (local) | `http://localhost:1234/v1` | `local-model` |
| Azure OpenAI | `https://{resource}.openai.azure.com/openai/deployments/{deployment}` | deployment name |

## Authentication

| Header | Value |
|--------|-------|
| `Authorization` | `Bearer YOUR_API_KEY` |
| `Content-Type` | `application/json` |

**Environment variables:**
- `OPENAI_API_KEY` — your API key
- `OPENAI_BASE_URL` — (optional) override for compatible endpoints, defaults to `https://api.openai.com/v1`
- `MODEL_NAME` — (optional) override model, defaults to `gpt-4o`

## `.env` file

```
OPENAI_API_KEY=your-api-key-here
# OPENAI_BASE_URL=https://api.openai.com/v1
# MODEL_NAME=gpt-4o
```

Get a key at https://platform.openai.com/api-keys

For compatible endpoints, set the base URL and model for your provider.

## Verify your key

```bash
source .env && curl -s "${OPENAI_BASE_URL:-https://api.openai.com/v1}/chat/completions" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"'"${MODEL_NAME:-gpt-4o}"'","messages":[{"role":"user","content":"ping"}],"max_tokens":10}' \
  | head -c 200
```

---

## Message Format

Messages are sent as `messages[]`. Each message has:

| Field | Type | Values |
|-------|------|--------|
| `role` | string | `"system"`, `"user"`, `"assistant"`, or `"tool"` |
| `content` | string or null | The message text (null for assistant messages with tool calls) |
| `tool_calls` | array | (assistant only) Tool calls the model wants to make |
| `tool_call_id` | string | (tool only) ID of the tool call this result is for |

---

## Request Body

### Minimal (text only)

```json
{
  "model": "gpt-4o",
  "messages": [
    { "role": "user", "content": "Hello!" }
  ]
}
```

### Full (system prompt + tools)

```json
{
  "model": "gpt-4o",
  "messages": [
    { "role": "system", "content": "You are a helpful coding assistant." },
    { "role": "user", "content": "What files are here?" }
  ],
  "tools": [{
    "type": "function",
    "function": {
      "name": "list_files",
      "description": "List files and directories at the given path",
      "parameters": {
        "type": "object",
        "properties": {
          "directory": { "type": "string", "description": "Directory path to list" }
        },
        "required": ["directory"]
      }
    }
  }]
}
```

---

## System Prompt

The system prompt is just the first message with `role: "system"`:

```json
{
  "model": "gpt-4o",
  "messages": [
    { "role": "system", "content": "You are a coding assistant named Marvin." },
    { "role": "user", "content": "Hello!" }
  ]
}
```

The system message is always the first element in the `messages` array and is sent with every request.

---

## Response Format

### Text response

```json
{
  "choices": [{
    "message": {
      "role": "assistant",
      "content": "Response text here"
    },
    "finish_reason": "stop"
  }]
}
```

**Extract text:** `response.choices[0].message.content`

### Tool call response

```json
{
  "choices": [{
    "message": {
      "role": "assistant",
      "content": null,
      "tool_calls": [{
        "id": "call_abc123",
        "type": "function",
        "function": {
          "name": "list_files",
          "arguments": "{\"directory\": \".\"}"
        }
      }]
    },
    "finish_reason": "tool_calls"
  }]
}
```

**Detection:** Check if `choices[0].message.tool_calls` exists and is non-empty. You can also check `finish_reason === "tool_calls"`.

**⚠️ Important:** `function.arguments` is a **JSON string**, not an object. You must parse it: `JSON.parse(tool_call.function.arguments)`.

### Multiple tool calls in one response

The model may return multiple tool calls in a single response:

```json
{
  "tool_calls": [
    { "id": "call_abc", "type": "function", "function": { "name": "list_files", "arguments": "{\"directory\": \"src\"}" } },
    { "id": "call_def", "type": "function", "function": { "name": "read_file", "arguments": "{\"path\": \"README.md\"}" } }
  ]
}
```

Handle each one and send all results back as separate `tool`-role messages, each referencing its `tool_call_id`.

---

## Tool Definitions

Tools are defined in the `tools` array:

```json
{
  "tools": [{
    "type": "function",
    "function": {
      "name": "list_files",
      "description": "List files and directories at the given path",
      "parameters": {
        "type": "object",
        "properties": {
          "directory": {
            "type": "string",
            "description": "Directory path to list"
          }
        },
        "required": ["directory"]
      }
    }
  }]
}
```

The `parameters` field uses **JSON Schema** format (same as OpenAPI).

### Tool Choice (optional)

Control how the model uses tools:

```json
{ "tool_choice": "auto" }
```

| Value | Behavior |
|-------|----------|
| `"auto"` | Model decides whether to call tools (default) |
| `"required"` | Model must call at least one tool |
| `"none"` | Model cannot call tools |
| `{"type": "function", "function": {"name": "..."}}` | Force a specific tool |

---

## Full Tool-Use Round Trip

### 1. User sends a message with tool definitions

```json
{
  "model": "gpt-4o",
  "messages": [
    { "role": "user", "content": "What files are in the current directory?" }
  ],
  "tools": [{
    "type": "function",
    "function": {
      "name": "list_files",
      "description": "List files and directories at the given path",
      "parameters": {
        "type": "object",
        "properties": {
          "directory": { "type": "string", "description": "Directory path to list" }
        },
        "required": ["directory"]
      }
    }
  }]
}
```

### 2. Model responds with a tool call

```json
{
  "choices": [{
    "message": {
      "role": "assistant",
      "content": null,
      "tool_calls": [{
        "id": "call_abc123",
        "type": "function",
        "function": {
          "name": "list_files",
          "arguments": "{\"directory\": \".\"}"
        }
      }]
    },
    "finish_reason": "tool_calls"
  }]
}
```

### 3. Execute the tool and send the result back

Append the assistant's message (with tool_calls) AND the tool result to `messages`:

```json
{
  "model": "gpt-4o",
  "messages": [
    { "role": "user", "content": "What files are in the current directory?" },
    {
      "role": "assistant",
      "content": null,
      "tool_calls": [{
        "id": "call_abc123",
        "type": "function",
        "function": { "name": "list_files", "arguments": "{\"directory\": \".\"}" }
      }]
    },
    {
      "role": "tool",
      "tool_call_id": "call_abc123",
      "content": "main.py\nREADME.md\nutils.py"
    }
  ],
  "tools": [{...same tool definitions...}]
}
```

### 4. Model responds with text

```json
{
  "choices": [{
    "message": {
      "role": "assistant",
      "content": "The current directory contains three files: main.py, README.md, and utils.py."
    },
    "finish_reason": "stop"
  }]
}
```

---

## Common Pitfalls

- **`arguments` is a JSON string**: You must `JSON.parse()` the `function.arguments` field. It's a string, not an object. This is the #1 gotcha.
- **Forgetting `tool_call_id`**: Every tool result must reference the `id` from the corresponding `tool_calls` entry. Without it, the API returns an error.
- **Forgetting to append the assistant message**: When the model makes tool calls, you must append its full message (including `tool_calls`) to the conversation before adding the tool results.
- **`content: null` on tool call messages**: When the model makes tool calls, `content` is typically `null`. Don't crash on this — check for tool_calls first, then fall back to content.
- **Model field is required**: Unlike Gemini (where the model is in the URL), OpenAI requires `model` in every request body.
