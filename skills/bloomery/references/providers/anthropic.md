# Anthropic API Reference (Raw HTTP)

Quick reference for making raw HTTP calls to the Anthropic Messages API. No SDK required — just HTTP POST with JSON.

## Endpoint

```
POST https://api.anthropic.com/v1/messages
```

**Default model:** `claude-sonnet-4-6`

## Authentication

| Header | Value |
|--------|-------|
| `x-api-key` | `YOUR_API_KEY` |
| `anthropic-version` | `2023-06-01` |
| `content-type` | `application/json` |

**Environment variable:** `ANTHROPIC_API_KEY`

**Note:** Anthropic uses `x-api-key` (not `Authorization: Bearer`). The `anthropic-version` header is required on every request.

## `.env` file

```
ANTHROPIC_API_KEY=your-api-key-here
```

Get a key at https://console.anthropic.com/settings/keys

## Verify your key

```bash
source .env && curl -s "https://api.anthropic.com/v1/messages" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-sonnet-4-6","max_tokens":50,"messages":[{"role":"user","content":"ping"}]}' \
  | head -c 200
```

---

## Message Format

Messages are sent as `messages[]`. Each message has:

| Field | Type | Values |
|-------|------|--------|
| `role` | string | `"user"` or `"assistant"` |
| `content` | string or array | Text string or array of content blocks |

### Content block types

**Text block:**
```json
{ "type": "text", "text": "some text" }
```

**Tool use block** (in assistant responses):
```json
{
  "type": "tool_use",
  "id": "toolu_abc123",
  "name": "read_file",
  "input": { "path": "main.py" }
}
```

**Tool result block** (in user messages):
```json
{
  "type": "tool_result",
  "tool_use_id": "toolu_abc123",
  "content": "file contents here"
}
```

**Note:** Anthropic only uses two roles: `user` and `assistant`. Tool results are sent as content blocks inside a `user`-role message.

---

## Request Body

### Minimal (text only)

```json
{
  "model": "claude-sonnet-4-6",
  "max_tokens": 8096,
  "messages": [
    { "role": "user", "content": "Hello!" }
  ]
}
```

**⚠️ `max_tokens` is required.** Unlike other APIs, Anthropic requires you to specify the maximum number of tokens in the response. Use `8096` as a sensible default.

### Full (system prompt + tools)

```json
{
  "model": "claude-sonnet-4-6",
  "max_tokens": 8096,
  "system": "You are a helpful coding assistant.",
  "messages": [...],
  "tools": [{
    "name": "list_files",
    "description": "List files and directories at the given path",
    "input_schema": {
      "type": "object",
      "properties": {
        "directory": { "type": "string", "description": "Directory path to list" }
      },
      "required": ["directory"]
    }
  }]
}
```

---

## System Prompt

The system prompt is a top-level `system` field (sibling to `messages`):

```json
{
  "model": "claude-sonnet-4-6",
  "max_tokens": 8096,
  "system": "You are a coding assistant named Marvin. Use tools proactively.",
  "messages": [...]
}
```

The `system` field is a string (or an array of content blocks for advanced use). It is NOT part of the `messages` array.

---

## Response Format

### Text response

```json
{
  "id": "msg_abc123",
  "type": "message",
  "role": "assistant",
  "content": [
    { "type": "text", "text": "Response text here" }
  ],
  "stop_reason": "end_turn"
}
```

**Extract text:** `response.content[0].text` (when the block type is `"text"`)

### Tool use response

```json
{
  "id": "msg_abc123",
  "type": "message",
  "role": "assistant",
  "content": [
    { "type": "text", "text": "I'll check the directory for you." },
    {
      "type": "tool_use",
      "id": "toolu_abc123",
      "name": "list_files",
      "input": { "directory": "." }
    }
  ],
  "stop_reason": "tool_use"
}
```

**Detection:** Check if any block in `response.content` has `type === "tool_use"`. You can also check `stop_reason === "tool_use"`.

**Note:** Anthropic often includes both a text block AND a tool_use block in the same response. The text is the model "thinking out loud" before using the tool. Include the full content array in conversation history.

### Multiple tool calls in one response

The model may return multiple `tool_use` blocks in a single response:

```json
{
  "content": [
    { "type": "tool_use", "id": "toolu_abc", "name": "list_files", "input": { "directory": "src" } },
    { "type": "tool_use", "id": "toolu_def", "name": "read_file", "input": { "path": "README.md" } }
  ]
}
```

Handle each one and send all results back as separate `tool_result` blocks in a single `user`-role message.

---

## Tool Definitions

Tools are defined in the top-level `tools` array:

```json
{
  "tools": [{
    "name": "list_files",
    "description": "List files and directories at the given path",
    "input_schema": {
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
}
```

**Key difference from OpenAI/Gemini:** The schema field is called `input_schema`, not `parameters`. The schema format is standard JSON Schema.

### Tool Choice (optional)

Control how the model uses tools:

```json
{ "tool_choice": { "type": "auto" } }
```

| Value | Behavior |
|-------|----------|
| `{"type": "auto"}` | Model decides whether to call tools (default) |
| `{"type": "any"}` | Model must call at least one tool |
| `{"type": "tool", "name": "..."}` | Force a specific tool |

---

## Full Tool-Use Round Trip

### 1. User sends a message with tool definitions

```json
{
  "model": "claude-sonnet-4-6",
  "max_tokens": 8096,
  "messages": [
    { "role": "user", "content": "What files are in the current directory?" }
  ],
  "tools": [{
    "name": "list_files",
    "description": "List files and directories at the given path",
    "input_schema": {
      "type": "object",
      "properties": {
        "directory": { "type": "string", "description": "Directory path to list" }
      },
      "required": ["directory"]
    }
  }]
}
```

### 2. Model responds with a tool use

```json
{
  "role": "assistant",
  "content": [
    { "type": "text", "text": "I'll list the files for you." },
    {
      "type": "tool_use",
      "id": "toolu_abc123",
      "name": "list_files",
      "input": { "directory": "." }
    }
  ],
  "stop_reason": "tool_use"
}
```

### 3. Execute the tool and send the result back

Append the assistant's response AND the tool result to `messages`:

```json
{
  "model": "claude-sonnet-4-6",
  "max_tokens": 8096,
  "messages": [
    { "role": "user", "content": "What files are in the current directory?" },
    {
      "role": "assistant",
      "content": [
        { "type": "text", "text": "I'll list the files for you." },
        { "type": "tool_use", "id": "toolu_abc123", "name": "list_files", "input": { "directory": "." } }
      ]
    },
    {
      "role": "user",
      "content": [{
        "type": "tool_result",
        "tool_use_id": "toolu_abc123",
        "content": "main.py\nREADME.md\nutils.py"
      }]
    }
  ],
  "tools": [{...same tool definitions...}]
}
```

**Note:** Tool results are sent as `role: "user"` with `tool_result` content blocks — NOT a separate `"tool"` role.

### 4. Model responds with text

```json
{
  "role": "assistant",
  "content": [
    { "type": "text", "text": "The current directory contains three files: main.py, README.md, and utils.py." }
  ],
  "stop_reason": "end_turn"
}
```

---

## Common Pitfalls

- **`max_tokens` is required**: Every request must include `max_tokens`. Omitting it returns an error. Use `8096` as a default.
- **`anthropic-version` header is required**: Must be present on every request. Use `2023-06-01`.
- **Tool results use `role: "user"`**: Unlike OpenAI (`role: "tool"`) and Gemini (`role: "function"`), Anthropic sends tool results as user messages with `tool_result` content blocks.
- **`tool_use_id` must match**: Each `tool_result` block must reference the `id` from the corresponding `tool_use` block. Without it, the API returns an error.
- **`input` is an object, not a string**: Unlike OpenAI where `arguments` is a JSON string, Anthropic's `input` is already a parsed object. No need to `JSON.parse()`.
- **`input_schema` not `parameters`**: The tool schema field is called `input_schema` in Anthropic, not `parameters` as in OpenAI/Gemini.
- **Content can be string or array**: For simple text, `content: "hello"` works. For tool results, `content` must be an array of content blocks. Be consistent — using arrays everywhere is safer.
- **Include full assistant content**: When the model responds with both text and tool_use blocks, append the complete `content` array to conversation history — don't strip the text.
