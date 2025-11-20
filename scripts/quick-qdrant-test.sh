#!/bin/bash

echo "🚀 Быстрый тест Qdrant..."

echo "1. Health check:"
curl -s http://localhost:6333/health | jq '.status'

echo -e "\n2. Коллекции:"
curl -s http://localhost:6333/collections | jq '.result.collections[].name'

echo -e "\n3. Коллекция documents:"
DOC_INFO=$(curl -s http://localhost:6333/collections/documents)
echo "   Status: $(echo $DOC_INFO | jq -r '.result.status')"
echo "   Points: $(echo $DOC_INFO | jq -r '.result.points_count')"
echo "   Vectors: $(echo $DOC_INFO | jq -r '.result.vectors_count')"

echo -e "\n4. Пример документа:"
curl -s "http://localhost:6333/collections/documents/points?limit=1" | jq '.result[0].payload.text'

echo -e "\n✅ Qdrant работает!"
