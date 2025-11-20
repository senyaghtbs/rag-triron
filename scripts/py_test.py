import requests
import json
import time

def test_rag_system():
    print("🚀 Тестируем RAG систему с данными...")
    
    # 1. Создаем коллекцию в Qdrant
    print("\n📁 Создаем коллекцию...")
    response = requests.put(
        "http://localhost:6333/collections/documents",
        json={
            "vectors": {
                "size": 384,
                "distance": "Cosine"
            }
        }
    )
    print(f"✅ Коллекция создана: {response.status_code}")
    
    # 2. Добавляем документы
    print("\n📝 Добавляем документы...")
    documents = [
        "Москва - столица России и самый крупный город страны",
        "Париж является столицей Франции и известен Эйфелевой башней",
        "Python - это язык программирования с простым и понятным синтаксисом",
        "Кубернетес помогает управлять контейнерами в кластере серверов",
        "Искусственный интеллект и машинное обучение активно развиваются",
        "Лондон столица Великобритании и финансовый центр Европы",
        "JavaScript используется для веб-разработки и создания интерактивных сайтов",
        "Дocker позволяет упаковывать приложения в контейнеры для простого развертывания"
    ]
    
    for i, doc in enumerate(documents):
        print(f"  Обрабатываем: {doc[:50]}...")
        
        # Получаем вектор из эмбеддера
        vector_resp = requests.post(
            "http://localhost:8080/vectors",
            json={"text": doc}
        )
        
        if vector_resp.status_code == 200:
            vector_data = vector_resp.json()
            vector = vector_data["vector"]
            
            # Добавляем в Qdrant
            response = requests.put(
                "http://localhost:6333/collections/documents/points?wait=true",
                json={
                    "points": [{
                        "id": i + 1,
                        "vector": vector,
                        "payload": {
                            "text": doc,
                            "doc_id": i,
                            "category": "география" if "столица" in doc else "технологии"
                        }
                    }]
                }
            )
            
            if response.status_code == 200:
                print(f"    ✅ Успешно добавлен (ID: {i+1})")
            else:
                print(f"    ❌ Ошибка добавления: {response.status_code}")
        else:
            print(f"    ❌ Ошибка эмбеддера: {vector_resp.status_code}")
        
        time.sleep(0.5)  # Пауза между запросами
    
    # 3. Проверяем что данные добавились
    print("\n📊 Проверяем количество документов...")
    count_response = requests.get("http://localhost:6333/collections/documents/points/count")
    if count_response.status_code == 200:
        count = count_response.json()["result"]["count"]
        print(f"✅ В коллекции {count} документов")
    
    # 4. Тестируем поиск
    print("\n🔍 Тестируем поиск...")
    test_queries = [
        "столица",
        "программирование", 
        "контейнеры",
        "город России",
        "веб-разработка",
        "искусственный интеллект"
    ]
    
    for query in test_queries:
        print(f"\nПоиск: '{query}'")
        
        # Получаем вектор для запроса
        query_vector_resp = requests.post(
            "http://localhost:8080/vectors",
            json={"text": query}
        )
        
        if query_vector_resp.status_code == 200:
            query_vector = query_vector_resp.json()["vector"]
            
            # Ищем в Qdrant
            search_resp = requests.post(
                "http://localhost:6333/collections/documents/points/search",
                json={
                    "vector": query_vector,
                    "limit": 3,
                    "with_payload": True,
                    "score_threshold": 0.3
                }
            )
            
            if search_resp.status_code == 200:
                results = search_resp.json()
                if results.get("result"):
                    for i, hit in enumerate(results["result"], 1):
                        text = hit["payload"]["text"]
                        score = hit["score"]
                        category = hit["payload"]["category"]
                        print(f"  {i}. [{category}] {text}")
                        print(f"     ⭐ Сходство: {score:.3f}")
                else:
                    print("  ❌ Ничего не найдено")
            else:
                print(f"  ❌ Ошибка поиска: {search_resp.status_code}")
        else:
            print(f"  ❌ Ошибка эмбеддера для запроса: {query_vector_resp.status_code}")
    
    print("\n🎉 Тестирование завершено!")

if __name__ == "__main__":
    test_rag_system()
