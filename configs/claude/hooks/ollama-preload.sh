#!/bin/bash
# Preload qwen2.5:14b into Ollama on session start
# Runs async so it doesn't block Claude Code startup
curl -s --max-time 5 http://192.168.1.252:11434/api/generate \
  -d '{"model":"qwen2.5:14b","prompt":"hi","stream":false,"options":{"num_predict":1}}' \
  -o /dev/null &
