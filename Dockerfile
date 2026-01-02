FROM debian:bullseye as builder

RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libgtk-3-dev \
    liblzma-dev \
    chromium \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

ENV CHROME_EXECUTABLE=/usr/bin/chromium

ENV FLUTTER_HOME="/opt/flutter"
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

RUN git clone https://github.com/flutter/flutter.git -b stable $FLUTTER_HOME
WORKDIR $FLUTTER_HOME
RUN flutter config --enable-web
RUN flutter precache --web
RUN flutter doctor

WORKDIR /app
COPY frontend/ ./frontend/
COPY client_sdk/ ./client_sdk/

WORKDIR /app/frontend

RUN flutter pub get
RUN flutter build web --release

FROM python:3.11-slim

WORKDIR /app

# Copy built web files from builder stage
COPY --from=builder /app/frontend/build/web /app/web

# Expose port
EXPOSE 8080

# Serve static files with Python's built-in HTTP server
CMD ["python", "-m", "http.server", "8080", "--directory", "/app/web"]
