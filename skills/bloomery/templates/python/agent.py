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

API_KEY = os.environ.get("{{API_KEY_VAR}}")
if not API_KEY:
    print("Missing {{API_KEY_VAR}} in .env file")
    exit(1)

def main():
    while True:
        try:
            user_input = input("> ")
        except (EOFError, KeyboardInterrupt):
            break
        # TODO: send to LLM API and print response

main()
