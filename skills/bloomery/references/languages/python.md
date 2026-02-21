# Python Setup

## Runtime

**Zero setup required.**

```bash
mkdir <agent-name> && cd <agent-name>
```

Create `agent.py` and run with:
```bash
python3 agent.py
```

## Standard Library Modules

All stdlib, no pip install needed:

| Need | Import |
|------|--------|
| HTTP | `from urllib.request import urlopen, Request` |
| JSON | `import json` |
| Stdin | `input()` built-in |
| Run commands | `import subprocess` |
| Files | `open()`, `import os`, `pathlib.Path` |

## Starter File

Write this as `agent.py`. Replace `GEMINI_API_KEY` with the correct env var for the chosen provider (see Provider Env Vars in SKILL.md). For OpenAI, also add `BASE_URL` and `MODEL` variables after the API key check.

```python
import json
import os
from urllib.request import urlopen, Request

# Load .env file
with open(".env") as f:
    for line in f:
        if "=" in line:
            key, value = line.strip().split("=", 1)
            value = value.strip()
            if value and not value.startswith("#"):
                os.environ[key.strip()] = value

API_KEY = os.environ.get("GEMINI_API_KEY")
if not API_KEY:
    print("Missing GEMINI_API_KEY in .env file")
    exit(1)

def main():
    while True:
        try:
            user_input = input("> ")
        except (EOFError, KeyboardInterrupt):
            break
        # TODO: send to LLM API and print response

main()
```

## Language Hints for Specific Steps

### Step 7 (Bash Tool): `subprocess.run` doesn't throw on non-zero exit codes
Python's `subprocess.run` returns a `CompletedProcess` object even when the command fails. Use `capture_output=True, text=True, timeout=30` and check `result.returncode`. Both `result.stdout` and `result.stderr` are always available. This is simpler than most languages — no try/catch needed for the exit code, just check the return code and combine stdout+stderr.

## OpenAI Variant

For **OpenAI**, add after the API_KEY check:
```python
BASE_URL = os.environ.get("OPENAI_BASE_URL", "https://api.openai.com/v1")
MODEL = os.environ.get("MODEL_NAME", "gpt-4o")
```
