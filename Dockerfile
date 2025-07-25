FROM debian:latest

RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash flutter

ENV FLUTTER_HOME="/opt/flutter"
ENV PATH="$FLUTTER_HOME/bin:$PATH"

RUN git clone https://github.com/flutter/flutter.git $FLUTTER_HOME
WORKDIR $FLUTTER_HOME
RUN git fetch && git checkout 3.32.8
RUN flutter config --enable-web

RUN chown -R flutter:flutter $FLUTTER_HOME

WORKDIR /app
COPY frontend/ .

RUN chown -R flutter:flutter /app

USER flutter

RUN flutter pub get
RUN flutter build web --release

EXPOSE 8080

CMD ["python3", "-m", "http.server", "8080", "--directory", "build/web"]
