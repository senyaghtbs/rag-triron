#!/bin/bash

API_KEY="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"

echo "🔑 Тестируем API ключ OpenRouter..."

curl -s -X POST "https://openrouter.ai/api/v1/chat/completions" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -H "HTTP-Referer: https://test.com" \
  -H "X-Title: Test" \
  -d '{
    "model": "deepseek/deepseek-chat",
    "messages": [
      {"role": "user", "content": "Привет! Ответь коротко: что такое swag?"}
    ],
    "max_tokens": 100
  }' | jq '.choices[0].message.content'

