#!/bin/bash

echo "🚀 Запускаем порт-форвардинг..."
kubectl port-forward -n rag-system svc/rag-system-qdrant 6333:6333 &
QD_PID=$!

kubectl port-forward -n rag-system svc/rag-system-embedder 8080:8080 &
EMBED_PID=$!

echo "⏳ Ждем запуска..."
sleep 3

echo "🔍 Тестируем Qdrant..."
curl -s http://localhost:6333 | jq '.title'

echo "🔍 Тестируем Embedder..."
curl -s -X POST http://localhost:8080/vectors \
  -H "Content-Type: application/json" \
  -d '{"text": "test"}' | jq '.dim'

echo "🧹 Останавливаем порт-форвардинг..."
kill $QD_PID $EMBED_PID

echo "✅ Тест завершен"
