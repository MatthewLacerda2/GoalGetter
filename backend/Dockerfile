FROM python:3.14-slim

WORKDIR /app

# System packages only. No compiler and no libpq headers: on 3.14 every
# dependency in requirements.txt ships a wheel, so the build compiles nothing
# (#171). curl is the compose healthcheck.
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy only requirements first (better layer caching)
# This layer is cached unless requirements.txt changes
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy code (this invalidates cache when code changes, not dependencies)
COPY . ./backend/


EXPOSE 8000

CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"]
