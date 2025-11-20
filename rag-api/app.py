import os
import tritonclient.http as httpclient
from typing import List
import numpy as np
from transformers import AutoTokenizer
import logging
from fastapi import FastAPI, HTTPException
import requests
import time

app = FastAPI()
logger = logging.getLogger(__name__)

# Конфигурация
QDRANT_URL = os.getenv("QDRANT_URL", "http://rag-system-qdrant:6333")
TRITON_URL = os.getenv("TRITON_URL", "http://rag-system-triton:8000")
EMBEDDER_MODEL = os.getenv("EMBEDDER_MODEL", "embedder")
DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY", "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")

class TritonEmbedder:
    def __init__(self):
        self.triton_url = TRITON_URL
        self.model_name = EMBEDDER_MODEL
        self.client = httpclient.InferenceServerClient(url=self.triton_url)
        
        # Инициализация токенизатора
        self.tokenizer = AutoTokenizer.from_pretrained('sentence-transformers/all-MiniLM-L6-v2')
        if self.tokenizer.pad_token is None:
            self.tokenizer.pad_token = self.tokenizer.eos_token
        
        logger.info(f"Initialized TritonEmbedder with URL: {self.triton_url}, model: {self.model_name}")
    
    def embed_text(self, text: str) -> List[float]:
        """Создание эмбеддинга для одного текста"""
        try:
            # Препроцессинг текста
            processed_text = self._preprocess_texts([text])
            
            # Подготовка входных данных для Triton
            inputs = []
            
            # input_ids
            input_ids = httpclient.InferInput(
                "input_ids", 
                processed_text["input_ids"].shape, 
                "INT64"
            )
            input_ids.set_data_from_numpy(processed_text["input_ids"].astype(np.int64))
            inputs.append(input_ids)
            
            # attention_mask
            attention_mask = httpclient.InferInput(
                "attention_mask",
                processed_text["attention_mask"].shape,
                "INT64"
            )
            attention_mask.set_data_from_numpy(processed_text["attention_mask"].astype(np.int64))
            inputs.append(attention_mask)
            
            # Выход
            outputs = [httpclient.InferRequestedOutput("embeddings")]
            
            # Выполнение запроса
            response = self.client.infer(
                model_name=self.model_name,
                inputs=inputs,
                outputs=outputs
            )
            
            embeddings = response.as_numpy("embeddings")
            # Возвращаем первый эмбеддинг из батча
            return embeddings[0].tolist()
            
        except Exception as e:
            logger.error(f"Error in embed_text: {e}")
            raise
    
    def _preprocess_texts(self, texts: List[str]):
        """Препроцессинг текстов для модели"""
        # Токенизация
        encoded = self.tokenizer(
            texts,
            padding=True,
            truncation=True,
            max_length=512,
            return_tensors="np"
        )
        
        return {
            "input_ids": encoded["input_ids"],
            "attention_mask": encoded["attention_mask"]
        }

# Инициализация эмбеддера
embedder = TritonEmbedder()

def call_deepseek(prompt: str):
    """Вызов DeepSeek API"""
    try:
        response = requests.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {DEEPSEEK_API_KEY}",
                "Content-Type": "application/json"
            },
            json={
                "model": "deepseek/deepseek-chat",
                "messages": [{"role": "user", "content": prompt}],
                "max_tokens": 1000
            },
            timeout=60
        )
        if response.status_code == 200:
            result = response.json()
            return result["choices"][0]["message"]["content"]
        return f"API Error: {response.status_code}"
    except Exception as e:
        return f"Connection Error: {str(e)}"

@app.post("/query")
async def rag_query(request: dict):
    start_time = time.time()
    question = request.get("question", "").strip()
    if not question:
        raise HTTPException(400, "Question is required")

    collection = request.get("collection", "documents")
    limit = request.get("limit", 5)

    try:
        # 1. Get embedding from Triton
        query_vector = embedder.embed_text(question)

        # 2. Search in Qdrant
        search_response = requests.post(
            f"{QDRANT_URL}/collections/{collection}/points/search",
            json={
                "vector": query_vector,
                "limit": limit,
                "with_payload": True
            },
            timeout=10
        )
        search_results = search_response.json()

        if not search_results.get("result"):
            return {
                "answer": "No relevant information found.",
                "sources": [],
                "processing_time": round(time.time() - start_time, 2)
            }

        # 3. Prepare context
        sources = []
        for hit in search_results["result"]:
            sources.append({
                "text": hit["payload"]["text"],
                "score": hit["score"]
            })

        context = "\n".join([hit["payload"]["text"] for hit in search_results["result"]])

        # 4. Generate answer with DeepSeek
        prompt = f"Context: {context}\n\nQuestion: {question}\n\nAnswer based on context:"
        answer = call_deepseek(prompt)

        return {
            "answer": answer,
            "sources": sources,
            "context_used": len(sources),
            "processing_time": round(time.time() - start_time, 2),
            "model": "deepseek-chat"
        }

    except Exception as e:
        raise HTTPException(500, f"RAG error: {str(e)}")

@app.get("/health")
async def health():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=9000)