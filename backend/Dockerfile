FROM python:3.11-slim

WORKDIR /app

# Install system dependencies (cached unless changed)
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy only requirements first (better layer caching)
# This layer is cached unless requirements.txt changes
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy code (this invalidates cache when code changes, not dependencies)
COPY backend/ ./backend/
COPY tests/ ./tests/

EXPOSE 8000

CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"]
