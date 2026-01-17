# Stage 1: Flutter base with dependencies (cached layer)
FROM debian:bullseye-slim AS flutter-base

RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    liblzma-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

ENV CHROME_EXECUTABLE=/usr/bin/chromium
ENV FLUTTER_HOME="/opt/flutter"
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

# Install Flutter (this layer will be cached unless Flutter version changes)
RUN git clone https://github.com/flutter/flutter.git -b stable $FLUTTER_HOME \
    && cd $FLUTTER_HOME \
    && flutter config --enable-web \
    && flutter precache --web

# Stage 2: Build Flutter app (rebuilds only when code/dependencies change)
FROM flutter-base AS builder

WORKDIR /app

# Copy dependency files first for better caching
COPY frontend/pubspec.yaml ./frontend/
COPY client_sdk/pubspec.yaml ./client_sdk/

WORKDIR /app/frontend

# Install dependencies (cached unless pubspec.yaml changes)
RUN flutter pub get

# Copy the rest of the code
WORKDIR /app
COPY frontend/ ./frontend/
COPY client_sdk/ ./client_sdk/

WORKDIR /app/frontend

# Accept BASE_URL as build argument
ARG BASE_URL
ENV BASE_URL=${BASE_URL}

# Build the app (rebuilds when code changes)
RUN flutter build web --release --web-renderer html --dart-define=BASE_URL=${BASE_URL}

FROM nginx:alpine

# Install wget for healthchecks
RUN apk add --no-cache wget

# Copy built web files from builder stage
COPY --from=builder /app/frontend/build/web /usr/share/nginx/html

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
