# The Flutter version, read from the one place it is written (#121): the pin in
# frontend/pubspec.yaml, which CI installs exactly and `make front-version`
# checks locally. This image used to clone whatever `stable` was on the day, so
# production was built by a different Flutter than the one every gate ran.
#
# Its own stage so the pin, not the whole pubspec, is what the Flutter layer
# depends on: COPY --from caches on the file's content, and /flutter-version
# only changes when the version does - a dependency bump does not re-clone it.
FROM debian:trixie-slim AS flutter-pin
COPY frontend/pubspec.yaml /pubspec.yaml
RUN sed -nE 's/^[[:space:]]+flutter:[[:space:]]*([0-9][^[:space:]#]*).*/\1/p' /pubspec.yaml \
      | head -n1 > /flutter-version \
    && test -s /flutter-version

# trixie (Debian 13), the current stable. bullseye's LTS ended in August 2026
# and its security archive answers 404, which is what broke this build (#162);
# bookworm was already the previous release, so the image moved on with #164.
FROM debian:trixie-slim AS flutter-base

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
ENV PUB_HOSTED_URL="https://pub.dev"

# Install the pinned Flutter (cached until the pin moves)
COPY --from=flutter-pin /flutter-version /flutter-version
RUN git clone https://github.com/flutter/flutter.git -b "$(cat /flutter-version)" --depth 1 $FLUTTER_HOME \
    && cd $FLUTTER_HOME \
    && flutter config --enable-web \
    && flutter precache --web

# Stage 2: Build Flutter app (rebuilds only when code/dependencies change)
FROM flutter-base AS builder

WORKDIR /app

# Copy dependency files first for better caching
COPY frontend/pubspec.yaml frontend/pubspec.lock ./frontend/

WORKDIR /app/frontend

# Install exactly what the committed lock says (#192), cached until either
# file changes. `--enforce-lockfile` fails the build instead of resolving
# anew when the lock is missing, disagrees with pubspec.yaml, or a package's
# content hash does not match: production ships the packages the gates ran
# against, never whatever pub.dev offers on the day of the deploy.
RUN flutter pub get --enforce-lockfile

# Copy the rest of the code
WORKDIR /app
COPY frontend/ ./frontend/

WORKDIR /app/frontend

RUN flutter pub get --enforce-lockfile

ARG BASE_URL
ENV BASE_URL=${BASE_URL}

RUN flutter build web --release --dart-define=BASE_URL=${BASE_URL}

FROM nginx:alpine

# Install wget for healthchecks
RUN apk add --no-cache wget

# Copy built web files from builder stage
COPY --from=builder /app/frontend/build/web /usr/share/nginx/html

# Copy custom nginx configuration
COPY frontend/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
