package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

var apiKey string
{{#OPENAI}}
var baseURL string
var modelName string
{{/OPENAI}}

func loadEnv() {
	data, err := os.ReadFile(".env")
	if err != nil {
		fmt.Fprintln(os.Stderr, "Could not read .env file:", err)
		os.Exit(1)
	}
	for _, line := range strings.Split(string(data), "\n") {
		if key, val, ok := strings.Cut(line, "="); ok {
			val = strings.TrimSpace(val)
			if val != "" && !strings.HasPrefix(val, "#") {
				os.Setenv(strings.TrimSpace(key), val)
			}
		}
	}
	apiKey = os.Getenv("{{API_KEY_VAR}}")
	if apiKey == "" {
		fmt.Fprintln(os.Stderr, "Missing {{API_KEY_VAR}} in .env file")
		os.Exit(1)
	}
{{#OPENAI}}
	baseURL = os.Getenv("OPENAI_BASE_URL")
	if baseURL == "" {
		baseURL = "https://api.openai.com/v1"
	}
	modelName = os.Getenv("MODEL_NAME")
	if modelName == "" {
		modelName = "gpt-4o"
	}
{{/OPENAI}}
}

func main() {
	loadEnv()
	scanner := bufio.NewScanner(os.Stdin)
	for {
		fmt.Print("> ")
		if !scanner.Scan() {
			break
		}
		input := scanner.Text()
		// TODO: send to LLM API and print response
		_ = input
	}
}
