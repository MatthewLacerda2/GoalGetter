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

RUN git clone https://github.com/flutter/flutter.git $FLUTTER_HOME
WORKDIR $FLUTTER_HOME
RUN git checkout 3.32.8
RUN flutter config --enable-web
RUN flutter doctor

WORKDIR /app
COPY frontend/ ./frontend/
COPY client_sdk/ ./client_sdk/

WORKDIR /app/frontend

RUN flutter pub get
RUN flutter build web --release

FROM nginx:alpine

RUN rm -rf /usr/share/nginx/html/*

COPY --from=builder /app/frontend/build/web /usr/share/nginx/html

# Copy nginx configuration for Docker
COPY nginx.docker.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
