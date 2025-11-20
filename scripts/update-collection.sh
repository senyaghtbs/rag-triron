#!/bin/bash

echo "🔄 Обновляем коллекцию для multilingual-e5-large..."

# Удаляем старую коллекцию
curl -X DELETE http://localhost:6333/collections/documents

# Создаем новую с размерностью 1024
curl -X PUT http://localhost:6333/collections/documents \
  -H "Content-Type: application/json" \
  -d '{
    "vectors": {
      "size": 1024,
      "distance": "Cosine"
    }
  }'

echo "✅ Коллекция обновлена для модели с размерностью 1024"
