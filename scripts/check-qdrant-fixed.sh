#!/bin/bash

echo "🔍 Проверка Qdrant (исправленные методы)..."

echo -e "\n📊 Информация о коллекции:"
curl -s http://localhost:6333/collections/documents | jq '.result | {status: .status, points_count: .points_count, vectors_count: .vectors_count}'

echo -e "\n🔢 Количество точек:"
curl -s -X POST http://localhost:6333/collections/documents/points/count \
  -H "Content-Type: application/json" \
  -d '{}' | jq '.result'

echo -e "\n📝 Первые 5 документов:"
curl -s "http://localhost:6333/collections/documents/points?limit=5" | jq '.result[] | {id: .id, payload: .payload}'

echo -e "\n🔍 Тестовый поиск:"

# Получаем вектор для "программирование"
VECTOR_RESP=$(curl -s -X POST http://localhost:8080/vectors \
  -H "Content-Type: application/json" \
  -d '{"text": "программирование"}')

echo "Размер вектора: $(echo $VECTOR_RESP | jq '.vector | length')"

VECTOR=$(echo $VECTOR_RESP | jq -r '.vector | @json')

curl -s -X POST http://localhost:6333/collections/documents/points/search \
  -H "Content-Type: application/json" \
  -d "{
    \"vector\": $VECTOR,
    \"limit\": 3,
    \"with_payload\": true
  }" | jq '.result[] | {id: .id, score: .score, text: .payload.text}'

echo -e "\n✅ Проверка завершена"
