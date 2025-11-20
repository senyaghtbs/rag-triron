# Используем более легкий образ
FROM python:3.9-alpine

WORKDIR /app

# Установка системных зависимостей
RUN apk add --no-cache \
    gcc \
    musl-dev \
    linux-headers

# Копирование requirements и установка Python зависимостей
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Копирование исходного кода
COPY . .

# Экспорт порта
EXPOSE 9000

# Запуск приложения
CMD ["python", "main.py"]