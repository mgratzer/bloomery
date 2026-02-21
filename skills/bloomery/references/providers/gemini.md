# Gemini API Reference (Raw HTTP)

Quick reference for making raw HTTP calls to the Gemini API. No SDK required — just HTTP POST with JSON.

## Endpoint

```
POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=API_KEY
```

**Default model:** `gemini-2.5-flash`

## Authentication

Two options (use whichever is easier in your language):

| Method | Format |
|--------|--------|
| Query parameter | `?key=YOUR_API_KEY` |
| Header | `x-goog-api-key: YOUR_API_KEY` |

**Environment variable:** `GEMINI_API_KEY`

## `.env` file

```
GEMINI_API_KEY=your-api-key-here
```

Get a free key at https://aistudio.google.com/apikey

## Verify your key

```bash
source .env && curl -s "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$GEMINI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"contents":[{"role":"user","parts":[{"text":"ping"}]}]}' \
  | head -c 200
```

---

## Message Format

Messages are sent as `contents[]`. Each message has:

| Field | Type | Values |
|-------|------|--------|
| `role` | string | `"user"`, `"model"`, or `"function"` |
| `parts` | array | Array of part objects |

### Part types

**Text:**
```json
{ "text": "some text" }
```

**Function call** (in model responses):
```json
{ "functionCall": { "name": "read_file", "args": { "path": "main.py" } } }
```

**Function response** (in function-role messages):
```json
{
  "functionResponse": {
    "name": "read_file",
    "response": { "name": "read_file", "content": "file contents here" }
  }
}
```

---

## Request Body

### Minimal (text only)

```json
{
  "contents": [
    { "role": "user", "parts": [{ "text": "Hello!" }] }
  ],
  "generationConfig": { "thinkingConfig": { "thinkingBudget": 0 } }
}
```

**⚠️ Always include `thinkingConfig: { thinkingBudget: 0 }`.** `gemini-2.5-flash` enables dynamic thinking by default. Without this, the model may return thinking parts (with `"thought": true`) before the actual text part, breaking the `parts[0].text` extraction path.

### Full (system prompt + tools + thinking disabled)

```json
{
  "systemInstruction": {
    "parts": [{ "text": "You are a helpful coding assistant." }]
  },
  "contents": [...],
  "tools": [{
    "functionDeclarations": [...]
  }],
  "generationConfig": {
    "thinkingConfig": { "thinkingBudget": 0 }
  }
}
```

---

## System Prompt

Use `systemInstruction` at the top level of the request body (sibling to `contents`):

```json
{
  "systemInstruction": {
    "parts": [{ "text": "You are a coding assistant named Marvin." }]
  },
  "contents": [...]
}
```

**Important:** `systemInstruction` does NOT have a `role` field — only `parts`. It is NOT part of the `contents` array.

---

## Response Format

### Text response

```json
{
  "candidates": [{
    "content": {
      "parts": [{ "text": "Response text here" }],
      "role": "model"
    },
    "finishReason": "STOP"
  }]
}
```

**Extract text:** `response.candidates[0].content.parts[0].text`

### Function call response

```json
{
  "candidates": [{
    "content": {
      "parts": [{
        "functionCall": {
          "name": "list_files",
          "args": { "directory": "." }
        }
      }],
      "role": "model"
    },
    "finishReason": "STOP"
  }]
}
```

**Detection:** Check if any part in `candidates[0].content.parts` contains a `functionCall` object. Do NOT rely on `finishReason` — you must inspect the parts directly.

### Multiple function calls in one response

The model may return multiple `functionCall` parts in a single response:

```json
{
  "parts": [
    { "functionCall": { "name": "list_files", "args": { "directory": "src" } } },
    { "functionCall": { "name": "read_file", "args": { "path": "README.md" } } }
  ]
}
```

Handle each one and send all results back in a single `function`-role message with multiple `functionResponse` parts.

---

## Tool Definitions

Tools are defined in the `tools` array using `functionDeclarations`:

```json
{
  "tools": [{
    "functionDeclarations": [{
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
    }]
  }]
}
```

The `parameters` field uses **OpenAPI 3.0 schema** format.

### Tool Config (optional)

Control how the model uses tools:

```json
{
  "toolConfig": {
    "functionCallingConfig": { "mode": "AUTO" }
  }
}
```

| Mode | Behavior |
|------|----------|
| `AUTO` | Model decides whether to call tools (default) |
| `ANY` | Model must call at least one tool |
| `NONE` | Model cannot call tools |

---

## Full Tool-Use Round Trip

### 1. User sends a message with tool definitions

```json
{
  "contents": [
    { "role": "user", "parts": [{ "text": "What files are in the current directory?" }] }
  ],
  "tools": [{
    "functionDeclarations": [{
      "name": "list_files",
      "description": "List files and directories at the given path",
      "parameters": {
        "type": "object",
        "properties": {
          "directory": { "type": "string", "description": "Directory path to list" }
        },
        "required": ["directory"]
      }
    }]
  }],
  "generationConfig": { "thinkingConfig": { "thinkingBudget": 0 } }
}
```

### 2. Model responds with a function call

```json
{
  "candidates": [{
    "content": {
      "parts": [{ "functionCall": { "name": "list_files", "args": { "directory": "." } } }],
      "role": "model"
    }
  }]
}
```

### 3. Execute the tool and send the result back

Append the model's response AND the tool result to `contents`:

```json
{
  "contents": [
    { "role": "user", "parts": [{ "text": "What files are in the current directory?" }] },
    {
      "role": "model",
      "parts": [{ "functionCall": { "name": "list_files", "args": { "directory": "." } } }]
    },
    {
      "role": "function",
      "parts": [{
        "functionResponse": {
          "name": "list_files",
          "response": { "name": "list_files", "content": "main.py\nREADME.md\nutils.py" }
        }
      }]
    }
  ],
  "tools": [{...same tool definitions...}],
  "generationConfig": { "thinkingConfig": { "thinkingBudget": 0 } }
}
```

### 4. Model responds with text

```json
{
  "candidates": [{
    "content": {
      "parts": [{ "text": "The current directory contains three files: main.py, README.md, and utils.py." }],
      "role": "model"
    }
  }]
}
```

---

## Common Pitfalls

- **Forgetting to append the model's response**: Every API call must include the full conversation history in `contents`. After a model response, append its `content` as a `model`-role message.
- **Wrong role for tool results**: Tool results use `role: "function"`, not `role: "user"`. Note: some newer Google documentation shows `role: "user"` for tool results — both work with the `v1beta` endpoint, but `role: "function"` is the canonical choice for `functionResponse` parts.
- **Missing `response.name`**: The `functionResponse` object needs `name` at both the top level and inside `response`.
- **Not checking parts for functionCall**: Tool calls are detected by inspecting `parts`, not `finishReason`.
- **Sending empty contents**: The `contents` array must have at least one message.
- **Thinking tokens**: With `thinkingBudget: 0`, thinking is disabled. If you enable thinking later, be aware that thinking parts appear in the response and should be filtered when displaying output.
