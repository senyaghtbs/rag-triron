#!/bin/bash

echo "🧪 Тестируем RAG с Wikipedia данными..."

questions=(
    "Что такое Python и для чего он используется?"
    "Объясни что такое Docker контейнеры"
    "Как работает Kubernetes?"
    "Что такое машинное обучение?"
    "Для чего используется React?"
    "Что такое Git и зачем он нужен?"
    "Расскажи про базы данных и SQL"
    "Какие возможности у JavaScript?"
    "Что включает в себя искусственный интеллект?"
    "В чем разница между Docker и Kubernetes?"
)

for question in "${questions[@]}"; do
    echo -e "\n🔍 Вопрос: $question"
    
    response=$(curl -s -X POST http://localhost:9000/query \
      -H "Content-Type: application/json" \
      -d "{\"question\": \"$question\", \"collection\": \"documents\"}")
    
    echo "🤖 Ответ:"
    echo "$response" | jq -r '.answer' | head -6
    echo "⏱️ Время: $(echo "$response" | jq -r '.processing_time')с"
    echo "📚 Источников: $(echo "$response" | jq -r '.sources | length')"
    echo "---"
done
