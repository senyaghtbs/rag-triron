#!/bin/bash

echo "🧪 Тестируем multilingual-e5-large модель..."

# 1. Обновляем коллекцию
curl -X DELETE http://localhost:6333/collections/documents 2>/dev/null
curl -X PUT http://localhost:6333/collections/documents \
  -H "Content-Type: application/json" \
  -d '{
    "vectors": {
      "size": 1024,
      "distance": "Cosine"
    }
  }'

echo "✅ Коллекция обновлена (размерность: 1024)"

# 2. Добавляем многоязычные документы
echo -e "\n📝 Добавляем многоязычные документы..."

documents=(
    "Москва - столица России. Moscow is the capital of Russia."
    "Париж - столица Франции. Paris is the capital of France."
    "Python - мощный язык программирования. Python is a powerful programming language."
    "Кубернетес управляет контейнерами. Kubernetes manages containers."
    "Искусственный интеллект меняет мир. Artificial intelligence is changing the world."
   "Машинное обучение для анализа данных. Machine learning for data analysis."
    "Глубокое обучение и нейронные сети. Deep learning and neural networks."
)

for i in "${!documents[@]}"; do
    doc="${documents[$i]}"
    echo "  Добавляем: ${doc:0:60}..."
    
    # Получаем вектор от новой модели
    VECTOR_RESP=$(curl -s -X POST http://localhost:8080/vectors \
      -H "Content-Type: application/json" \
      -d "{\"text\": \"$doc\"}")
    
    VECTOR=$(echo $VECTOR_RESP | jq -r '.vector | @json')
    
    # Добавляем в Qdrant
    curl -s -X PUT "http://localhost:6333/collections/documents/points?wait=true" \
      -H "Content-Type: application/json" \
      -d "{
        \"points\": [
          {
            \"id\": $((i+1)),
            \"vector\": $VECTOR,
            \"payload\": {
              \"text\": \"$doc\",
              \"language\": \"multilingual\"
            }
          }
        ]
      }" > /dev/null
    
    sleep 0.5
done

# 3. Тестируем поиск на разных языках
echo -e "\n🔍 Тестируем многоязычный поиск..."

queries=(
    "столица России"
    "capital of France" 
    "programming language"
    "container management"
    "artificial intelligence"
    "машинное обучение"
)

for query in "${queries[@]}"; do
    echo -e "\nПоиск: '$query'"
    
    # Получаем вектор для запроса
    QUERY_VECTOR_RESP=$(curl -s -X POST http://localhost:8080/vectors \
      -H "Content-Type: application/json" \
      -d "{\"text\": \"$query\"}")
    
    QUERY_VECTOR=$(echo $QUERY_VECTOR_RESP | jq -r '.vector | @json')
    
    # Ищем
    RESULTS=$(curl -s -X POST http://localhost:6333/collections/documents/points/search \
      -H "Content-Type: application/json" \
      -d "{
        \"vector\": $QUERY_VECTOR,
        \"limit\": 2,
        \"with_payload\": true
      }")
    
    echo "$RESULTS" | jq -r '.result[] | "  📄 \(.payload.text)"'
    echo "$RESULTS" | jq -r '.result[] | "     ⭐ Сходство: \(.score)"'
done

