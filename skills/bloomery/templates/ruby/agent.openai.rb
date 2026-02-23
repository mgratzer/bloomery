require "net/http"
require "uri"
require "json"

# Load .env file
File.readlines(".env").each do |line|
  key, value = line.strip.split("=", 2)
  next unless key && value && !value.empty? && !value.start_with?("#")
  ENV[key.strip] = value.strip
end

API_KEY = ENV["{{API_KEY_VAR}}"]
abort("Missing {{API_KEY_VAR}} in .env file") unless API_KEY && !API_KEY.empty?

BASE_URL = ENV["OPENAI_BASE_URL"] || "https://api.openai.com/v1"
MODEL = ENV["MODEL_NAME"] || "gpt-4o"

loop do
  print "> "
  input = gets
  break if input.nil?
  input = input.chomp
  # TODO: send to LLM API and print response
end
