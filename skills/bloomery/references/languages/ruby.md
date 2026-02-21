# Ruby Setup

## Runtime

**Zero setup required.**

```bash
mkdir <agent-name> && cd <agent-name>
```

Create `agent.rb` and run with:
```bash
ruby agent.rb
```

## Standard Library Modules

All stdlib, no gem install needed:

| Need | Import |
|------|--------|
| HTTP | `require "net/http"` and `require "uri"` |
| JSON | `require "json"` |
| Stdin | `gets` or `$stdin.gets` |
| Run commands | `require "open3"` with `Open3.capture3` |
| Files | `File.read`, `File.write`, `Dir.entries` (built-in) |

## Starter File

Write this as `agent.rb`. Replace `GEMINI_API_KEY` with the correct env var for the chosen provider (see Provider Env Vars in SKILL.md). For OpenAI, also add `BASE_URL` and `MODEL` variables after the API key check.

```ruby
require "net/http"
require "uri"
require "json"

# Load .env file
File.readlines(".env").each do |line|
  key, value = line.strip.split("=", 2)
  next unless key && value && !value.empty? && !value.start_with?("#")
  ENV[key.strip] = value.strip
end

API_KEY = ENV["GEMINI_API_KEY"]
abort("Missing GEMINI_API_KEY in .env file") unless API_KEY && !API_KEY.empty?

loop do
  print "> "
  input = gets
  break if input.nil?
  input = input.chomp
  # TODO: send to LLM API and print response
end
```

## Language Hints for Specific Steps

### Step 7 (Bash Tool): `Open3.capture3` doesn't throw on non-zero exit codes
Ruby's `Open3.capture3` returns `[stdout, stderr, status]` even when the command fails. Check `status.exitstatus` for the exit code. Both stdout and stderr are always available. This is straightforward — no begin/rescue needed for the exit code.

## OpenAI Variant

For **OpenAI**, add after the API_KEY check:
```ruby
BASE_URL = ENV["OPENAI_BASE_URL"] || "https://api.openai.com/v1"
MODEL = ENV["MODEL_NAME"] || "gpt-4o"
```
