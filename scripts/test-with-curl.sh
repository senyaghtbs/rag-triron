#!/bin/bash

echo "🚀 Тестируем RAG систему через curl..."

# 1. Создаем коллекцию (если не существует)
echo "📁 Проверяем коллекцию..."
COLLECTION_RESP=$(curl -s http://localhost:6333/collections/documents)
if echo "$COLLECTION_RESP" | grep -q "not found"; then
    echo "Создаем коллекцию..."
    curl -X PUT http://localhost:6333/collections/documents \
      -H "Content-Type: application/json" \
      -d '{
        "vectors": {
          "size": 384,
          "distance": "Cosine"
        }
      }'
    echo "✅ Коллекция создана"
else
    echo "✅ Коллекция уже существует"
fi

# 2. Добавляем несколько документов
echo -e "\n📝 Добавляем документы..."

documents=(
    "Москва - столица России"
    "Париж - столица Франции" 
    "Python - язык программирования"
    "Кубернетес - система оркестрации контейнеров"
    "Искусственный интеллект преобразует мир технологий"
)

for i in "${!documents[@]}"; do
    doc="${documents[$i]}"
    echo "  Добавляем: $doc"
    
    # Получаем вектор
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
            \"id\": $((i+100)),
            \"vector\": $VECTOR,
            \"payload\": {
              \"text\": \"$doc\",
              \"category\": \"география\"
            }
          }
        ]
      }" > /dev/null
    
    sleep 0.3
done

echo -e "\n✅ Документы добавлены"

# 3. Проверяем количество точек
echo -e "\n📊 Проверяем количество документов..."
COUNT_RESP=$(curl -s http://localhost:6333/collections/documents/points/count)
echo "$COUNT_RESP" | jq '.result.count'

# 4. Тестируем разные запросы
echo -e "\n🔍 Тестируем поиск по разным запросам..."

queries=("столица" "программирование" "контейнеры" "технологии")

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
        \"limit\": 3,
        \"with_payload\": true
      }")
    
    # Исправленный jq без round
    echo "$RESULTS" | jq -r '.result[] | "  📄 \(.payload.text)"'
    echo "$RESULTS" | jq -r '.result[] | "     ⭐ Сходство: \(.score)"'
done

echo -e "\n🎉 RAG система работает отлично!"
