# Build-Agent Curriculum

Eight incremental steps. Each builds on the last. By the end, the user has a working coding agent in ~300 lines.

All steps are **provider-agnostic**. The exact request/response format depends on the user's chosen provider — always refer them to their provider reference in `references/providers/` for the wire format details.

---

## Step 1: Basic Chat REPL

### Concept
Every agent starts as a conversation loop: read user input, send it to an LLM, print the response, repeat. This is the foundation everything else builds on. Get this working and the rest is incremental.

### Specification
Build a function that sends a message to the LLM and returns the response text. Then call it from the existing stdin loop. Here's the structure to guide the user through:

**1. Build the API call function.** Walk the user through creating a function (e.g., `chat(userMessage)`) that:
   - Constructs the request body with the user's message. Show them the exact JSON structure from the provider reference — the "Minimal (text only)" request body example.
   - Sets up the HTTP request: URL, headers (auth + content-type). Show the endpoint URL and auth mechanism from the provider reference.
   - Makes the HTTP POST and reads the response.
   - Parses the JSON response and extracts the text. Show them the exact extraction path from the provider reference (e.g., `response.candidates[0].content.parts[0].text` for Gemini).
   - Returns the extracted text.

**2. Wire it into the loop.** Replace the `// TODO` in the starter code:
   - Call the function with the user's input
   - Print the returned text

**3. Test it.** Run the program, type a message, see the response. That's it — they have a working chatbot.

**What to show the user:** Pull the "Minimal (text only)" request body and the response text extraction path directly from the provider reference. These are the two key pieces they need. Don't just say "see the reference" — show them the specific JSON structure and the specific path to extract.

**Gemini users only:** Make sure they include `"generationConfig": { "thinkingConfig": { "thinkingBudget": 0 } }` in every request, starting here in Step 1. `gemini-2.5-flash` uses dynamic thinking by default — without this field, the model may return a thinking part before the actual text, causing `parts[0].text` to return the internal reasoning instead of the response.

### Validation Criteria
- [ ] Has a function or block that constructs the API request body
- [ ] Makes HTTP POST to the correct endpoint for the provider
- [ ] API key read from environment variable (not hardcoded)
- [ ] Request body matches the provider's "Minimal" format
- [ ] Auth mechanism is correct (header or query param)
- [ ] Parses JSON response and extracts text from the correct path
- [ ] Runs in a loop (stdin read -> API call -> print -> repeat)
- [ ] Handles exit gracefully
- [ ] Actually works — can send a message and get a response

### Fast Track
Build a function that POSTs to your provider's chat endpoint and returns the response text. Wire it into the stdin loop. The provider reference has the exact request body under "Minimal (text only)" and the response extraction path under "Response Format".

### Meta Moment
"You just built a chat interface — the same thing you're talking to me through right now. The difference is I have memory, identity, and tools. You'll add those next."

---

## Step 2: Multi-Turn Conversation

### Concept
Right now each message is sent in isolation — the model has no memory. Real conversations require context. The fix: accumulate all messages (user and model) and send the full history with every request.

### Specification
Three changes to the existing code:

**1. Create a messages array** outside the loop (so it persists across iterations). This will hold the full conversation history.

**2. On each user input, append a user message to the array.** Show the user the exact message structure from the provider reference "Message Format" section. The key thing: each message has a role and content.
   - Point out which role is for user messages (e.g., `"user"` for all providers)
   - Show the structure (e.g., `{role: "user", parts: [{text: "..."}]}` for Gemini, `{role: "user", content: "..."}` for OpenAI/Anthropic)

**3. Update the API call** to send the full messages array instead of just the single message. This means refactoring the function from Step 1 — instead of taking a single message string, it should use the messages array (either passed in or accessed from the outer scope). Then after receiving the response, append the model's response to the array too.
   - Point out which role is for model responses (e.g., `"model"` for Gemini, `"assistant"` for OpenAI/Anthropic)
   - The exact object to append differs per provider — pull the example from the provider reference's "Message Format" section:
     - **Gemini**: append `response.candidates[0].content` — this is already the `{role: "model", parts: [...]}` object
     - **OpenAI**: append `response.choices[0].message` — this is the `{role: "assistant", content: "..."}` object
     - **Anthropic**: append `{role: "assistant", content: response.content}` — reconstruct it from the response's content array

**How to test:** Ask "my name is [X]", then in the next message ask "what's my name?" — if the model remembers, multi-turn is working.

### Validation Criteria
- [ ] A messages array exists and persists across loop iterations
- [ ] User messages are appended with the correct role and structure
- [ ] Model responses are appended with the correct role and structure
- [ ] The full array is sent with every API call (not just the latest message)
- [ ] Conversation memory works (model can reference earlier messages)

### Fast Track
Create a messages array outside the loop. Append user messages and model responses with the correct roles (see provider reference "Message Format" section). Send the full array each time. Test: "my name is X" then "what's my name?"

### Meta Moment
"I maintain conversation history too — that's how I know what you said earlier. Without this, every message would be like talking to someone with amnesia."

---

## Step 3: System Prompt

### Concept
Right now the agent is a blank slate — it doesn't know its name, its purpose, or how to behave. A system prompt gives the model identity and instructions before the conversation starts. This is how every real agent works: the coding agent you're talking to right now has a system prompt that tells it to be a coding assistant, use tools proactively, and work in the current directory.

### Specification
Two changes:

**1. Define the system prompt** as a string at the top of the program. It should tell the model:
   - Its name (the name the user chose in Step 0)
   - That it's a coding assistant that helps with programming tasks
   - That it has access to tools and should use them proactively (e.g., list files to understand the project before asking the user for paths)
   - The current working directory (use the actual cwd at runtime)
   - To be concise and helpful

   Example:
   ```
   You are <AGENT_NAME>, a coding assistant. You help users with programming tasks.

   You have access to tools that let you interact with the filesystem and run commands.
   Use tools proactively — for example, list files to understand a project before asking
   the user for specific paths. Always try to help by taking action, not just asking questions.

   Working directory: <CWD>
   ```

**2. Add it to the API request.** Show the user exactly how their provider handles system prompts — pull the example from the "System Prompt" section of the provider reference. The key difference to explain:
   - Some providers use a top-level field (separate from messages)
   - Some providers use a special role in the messages array
   - Show them the exact structure so they can add it to their existing request-building code

**How to test:** Ask "what's your name?" — the agent should respond with the name from the system prompt.

### Validation Criteria
- [ ] A system prompt string is defined with the agent's name and role
- [ ] The system prompt includes the current working directory
- [ ] The system prompt instructs the model to use tools proactively
- [ ] The system prompt is included in the API request using the correct mechanism
- [ ] The agent now responds with awareness of its identity (try asking "what's your name?")

### Fast Track
Define a system prompt string with agent name, role, tool-use instruction, and cwd. Add it to the API request — see the "System Prompt" section of your provider reference for the format. Test: ask "what's your name?"

### Meta Moment
"I have a system prompt too — it tells me who I am, describes my tools, and sets rules for how I should behave. Without it, I'd be a generic chatbot. Your agent just got its identity."

---

## Step 4: Tool Definition & Detection

### Concept
This is the first half of the big leap: turning a chatbot into an agent. Tools let the model take actions in the real world. The protocol: you declare tools in the request, and the model responds with a tool call instead of text. In this step, you'll define a tool and detect when the model wants to use it — but not execute it yet.

### Specification
Two things to build:

**1. Define the tool in the API request.** Show the user the exact tool declaration format from the "Tool Definitions" section of the provider reference. The tool needs:
   - Name: `list_files`
   - Description: `"List files and directories at the given path"`
   - Parameters: an object schema with a required `directory` string property
   - The declaration goes into the request body alongside the messages. Show them exactly where.

**2. Detect tool calls in the response.** After making the API call, the response might contain a tool call instead of (or in addition to) text. Show the user:
   - The exact response structure for a tool call from the "Function call response" / "Tool call response" section of the provider reference
   - How to check for it — what field to look at, what condition to test
   - Emphasize: they need to check BEFORE trying to extract text, otherwise they'll get null/undefined
   - When a tool call is detected, print it to the screen (e.g., `🔧 list_files({ directory: "." })`) — don't execute it yet, just log and break. Don't worry about appending to conversation history either — that's the next step.

   **Gemini users only:** Remind them to carry `"generationConfig": { "thinkingConfig": { "thinkingBudget": 0 } }` into the updated request body. It's easy to add the tool definitions and forget this field — without it, thinking tokens can appear in the parts array and interfere with both text extraction and tool call detection.

**How to test:** Ask "what files are in the current directory?" — the model should respond with a tool call (not text), and the program should print something like `🔧 list_files({ directory: "." })`. The tool isn't executed yet — that's the next step.

### Validation Criteria
- [ ] Tool definition included in the API request with correct format
- [ ] Tool has name, description, and parameter schema with `directory` property
- [ ] Response is checked for tool calls before extracting text
- [ ] When a tool call is detected, the function name and arguments are extracted
- [ ] Tool call is printed to stdout (name + args)
- [ ] Program doesn't crash when the model returns a tool call instead of text
- [ ] Actually works — ask about files and see the tool call printed

### Fast Track
Add a `list_files` tool definition to the request (see "Tool Definitions" in provider reference). After the API call, check for tool calls in the response (see "Function call response"). If found, print the tool name and args. Don't execute yet.

### Meta Moment
"You just saw the model ask to use a tool — that's exactly what happens when I decide to read a file or run a command. The model doesn't do the action itself; it asks the runtime to do it. Next, you'll build that runtime."

---

## Step 5: Tool Execution & Agentic Loop

### Concept
The model asked to use a tool — now you need to actually execute it and send the result back. Then the model might want to use another tool, or it might respond with text. This back-and-forth loop is the **agentic loop** — the core of every coding agent.

### Specification
Three things to build on top of Step 4:

**1. Execute the tool.** When a tool call is detected:
   - Extract the function name and arguments
   - If the name is `list_files`, read the directory using the language's stdlib
   - Convert the result to a string (e.g., join filenames with newlines)
   - Print the result to the screen (e.g., `📄 agent.ts, .env, .gitignore`)

**2. Send the result back.** This is the trickiest part. Show the user the "Full Tool-Use Round Trip" example from the provider reference. They need to:
   - Append the model's response (with the tool call) to the messages array
   - Append a tool result message to the messages array — show the exact format from the provider reference
   - Make another API call with the updated messages

**3. Build the agentic loop.** Wrap the API call in a loop. After each response, check:
   - Tool call → execute it, append model response + tool result to messages, continue the loop (call API again)
   - Text response → print it, append to messages, break out of the loop

   This inner loop is what makes it an *agent* — it keeps going until the model is done.

**Suggested code structure** (describe the flow — adapt to the user's language when presenting):
   - Start a loop
   - Call the API with the current messages
   - Check: does the response contain tool calls?
     - YES → print the tool call (name + args), execute it, print the result. Append the model's response and the tool results to messages. Continue the loop (call API again).
     - NO → it's a text response. Print it, append to messages, break out of the loop.

**Important edge cases** (mention but don't over-emphasize — the user will encounter these naturally as they add more tools):
- **Multiple tool calls in one response**: The model can return 2+ tool calls at once. Execute each one. **Provider-specific:** how you send the results back differs:
  - **Anthropic**: All results must go in a **single** `role: "user"` message with multiple `tool_result` content blocks. Sending separate messages causes an API error.
  - **Gemini**: All results go in a **single** `role: "function"` message with multiple `functionResponse` parts.
  - **OpenAI**: Each result is a separate `role: "tool"` message, one per tool call.
  - The provider reference shows the format under "Multiple tool calls in one response."
- **Mixed text + tool call responses** (especially Anthropic): The model may return both text and a tool call in the same response. The check should be: if there are ANY tool calls, execute them and continue the loop — don't break on text. Print the text, but keep going.

**How to test:** Ask "what files are in the current directory?" — you should see the tool call printed, the result printed, and then the model's text response summarizing the files.

### Validation Criteria
- [ ] `list_files` implementation actually reads the directory from the filesystem
- [ ] Tool results are printed to stdout
- [ ] Tool result is sent back in the correct format (see provider reference)
- [ ] Model's tool-call message is appended to conversation history
- [ ] Tool result message is appended to conversation history
- [ ] An inner loop continues calling the API until the model responds with text only (no tool calls)
- [ ] Actually works — ask "what files are in the current directory?" and get a real listing with the model's summary

### Fast Track
Execute the tool when detected (read directory for `list_files`). Send the result back: append model response + tool result to messages (see "Full Tool-Use Round Trip" in provider reference), call API again. Wrap in a loop until text-only response.

### Meta Moment
"I just used my Read tool to look at your code — that's the exact tool-use loop you just built. I sent a tool call, my runtime executed it, and the result came back to me. Your agent now works the same way."

---

## Step 6: Read File Tool

### Concept
One tool is a proof of concept. Two tools require a dispatcher — routing logic that calls the right function based on the tool name. This is a pattern you'll use for every tool you add from here on.

### Specification
Add the `read_file` tool:

1. **Declare** a new tool in the request:
   - Name: `read_file`
   - Description: `"Read the contents of a file at the given path"`
   - Parameters: an object with a required `path` string property

2. **Build a tool dispatcher**: instead of a single if-check, route by tool name:
   - `"list_files"` → list directory
   - `"read_file"` → read and return file contents

3. **Implement `read_file`**: read the file at the given path and return its contents as a string. Handle errors (file not found) gracefully by returning an error message string rather than crashing.

### Validation Criteria
- [ ] `read_file` declared in tool definitions with correct schema
- [ ] A dispatcher routes by function name (not a single hardcoded check)
- [ ] `read_file` reads actual file contents from disk
- [ ] Errors (e.g., file not found) return an error string, don't crash
- [ ] Both `list_files` and `read_file` work correctly

### Fast Track
Add `read_file` to tool definitions. Build a dispatcher that routes by tool name. Read and return file contents.

### Meta Moment
"Notice how adding the second tool was mostly about the routing, not the tool itself. That's the pattern — the hard part was the agentic loop. From here, each new tool is just a new case in your dispatcher."

---

## Step 7: Bash Tool

### Concept
A bash/shell tool is what makes an agent truly powerful — it can run any command the user could run. This is also the most dangerous tool, so think about what guardrails make sense.

### Specification
Add the `run_bash` tool:

1. **Declare** in tool definitions:
   - Name: `run_bash`
   - Description: `"Execute a bash command and return its output"`
   - Parameters: an object with a required `command` string property

2. **Implement**: spawn a subprocess that runs the command via the system shell. Capture both stdout and stderr. Return combined output as the tool result.

3. **Timeout**: add a reasonable timeout (e.g., 30 seconds) to prevent hanging on long-running commands.

4. **Error handling**: many commands exit with non-zero codes (e.g., `grep` finding no matches, `git diff` with changes). The agent must NOT crash on these — it should return the output (or error message) as a string, so the model can see what happened.

   **Important: wrap the entire command execution in a try/catch (or equivalent).** The key insight: a failed command still produces useful output. The tool should always return a string — either the stdout on success, or the stderr/error message on failure. Never let an exception bubble up and crash the agent.

   Guide the user toward this pattern:
   - Try to run the command
   - If it succeeds: return stdout (and stderr if any)
   - If it fails: catch the error, extract whatever output is available, return it as a string
   - Include the exit code in the returned string so the model knows what happened (e.g., `"Exit code 1: No matches found"`)

### Validation Criteria
- [ ] `run_bash` declared in tool definitions
- [ ] Implementation spawns a subprocess / child process
- [ ] Captures stdout and stderr
- [ ] Returns output as tool result string
- [ ] Has a timeout mechanism
- [ ] Non-zero exit codes handled gracefully (returned, not crashed)

### Fast Track
Add `run_bash` tool. Spawn a child process, capture stdout+stderr, return as result. Add a timeout. Handle non-zero exit codes.

### Meta Moment
"Your agent can now run arbitrary commands — just like I can with my Bash tool. Try asking it to `git status` or `ls -la`. This is where it starts to feel like a real coding agent."

---

## Step 8: Edit File Tool (Optional)

### Concept
Reading code is useful, but an agent that can modify code is transformative. This is the last tool that separates a "read-only assistant" from a true coding agent — with it, your agent can create and edit files just like the one you're talking to right now.

**However:** by this point you've already learned everything about how agents work — the agentic loop, tool protocol, and dispatcher pattern are all in place. This step is purely about string manipulation and file I/O, not new agent concepts. If you want to wrap up here, your agent is already fully functional for reading, running commands, and answering questions about code.

**Offer the user the choice:** implement the edit tool now, or skip to the completion celebration. If they skip, note that their agent can still create/edit files via `run_bash` — it's just less precise than a dedicated tool.

### Specification
Add the `edit_file` tool:

1. **Declare** in tool definitions:
   - Name: `edit_file`
   - Description: `"Edit a file by replacing a specific string with new content. Can also create new files."`
   - Parameters: an object with three required string properties:
     - `path` — file path to edit or create
     - `old_string` — string to find and replace (empty string to create new file or append)
     - `new_string` — replacement string

2. **Implement**:
   - If `old_string` is empty and file doesn't exist: create the file with `new_string` as contents
   - If `old_string` is empty and file exists: append `new_string` to the file
   - Otherwise: read the file, find `old_string`, replace with `new_string`, write back
   - If `old_string` is not found, return an error message
   - Validate that `old_string` appears exactly once to avoid ambiguous edits

### Validation Criteria
- [ ] `edit_file` declared in tool definitions with `path`, `old_string`, `new_string`
- [ ] Handles file creation (empty `old_string`, file doesn't exist)
- [ ] Handles find-and-replace in existing files
- [ ] Returns error if `old_string` not found
- [ ] Validates uniqueness of `old_string` (optional but good)
- [ ] Actually writes changes to disk

### Fast Track
Add `edit_file` with `path`, `old_string`, `new_string`. Empty `old_string` creates/appends. Otherwise find-and-replace. Error if not found.

### Meta Moment
"You've now built a complete coding agent. List files, read files, run commands, edit files — that's the same core toolkit I'm working with right now. Everything else is refinement."

### If the user skips
Move directly to Completion. Their agent has 3 tools (list_files, read_file, run_bash) which is already a fully working coding agent — it can read code, run commands, and even create/edit files via bash. Congratulate them the same way.

---

## Completion

When all steps are done (or the user skips Step 8), the user has a working coding agent with:
- A conversational interface with memory
- A system prompt that gives it identity and purpose
- Three or four tools (list_files, read_file, run_bash, and optionally edit_file)
- An agentic loop that keeps calling the API until the model stops requesting tools
- ~250-300 lines of code, no SDKs, just raw HTTP

### Celebrate and share

Congratulate the user — they just built a coding agent from scratch. This is a real accomplishment worth sharing.

**Offer to push to GitHub:**
1. Ask if they'd like to push their agent to a GitHub repo on their personal account so they can share it with colleagues.
2. If yes, help them set it up:
   - `git init` (if not already a repo)
   - Verify `.gitignore` is in place (`scaffold.sh` created it) — ensure `.build-agent-progress`, `.env`, `node_modules/`, etc. are listed
   - Create a short `README.md` with the agent's name, what it does, how to run it, and a note that it was built from scratch with no SDKs
   - Stage, commit, and push using `gh repo create <agent-name> --public --source=. --push`
3. Suggest they share the link with colleagues — it's a great conversation starter about how agents work under the hood. Anyone can clone it, set their API key, and try it out.

**Frame it as a teaching moment:** "You now understand how every coding agent works at its core — an LLM in a loop with tools. The next time you use any AI coding tool, you'll know exactly what's happening under the hood."

### Suggested next steps for the user
- Try asking the agent to search code — it can already do this via `run_bash` with `grep -rn` or `rg`
- Implement streaming for faster-feeling responses
- Add confirmation prompts before destructive operations (rm, overwriting files)
- Token counting and context window management
- Try pointing the agent at a different model/API (the patterns are the same)
