# Local gate runner. GitHub Actions calls these same targets, so a green
# `make check` locally is the same check CI runs - see .github/workflows/.
#
# Run the side you touched (`make backend` / `make frontend`) or `make check`
# for both, and see it pass BEFORE pushing.

SHELL := /bin/bash

# Flutter is not always on PATH on this machine; fall back to the known install.
FLUTTER ?= $(shell command -v flutter 2>/dev/null || echo $$HOME/development/flutter/bin/flutter)
DART    ?= $(dir $(FLUTTER))dart

# Backend deps live in the image, not a local venv (see CLAUDE.md).
# Run as the invoking user, and write no bytecode or pytest cache: as root, the
# container left root-owned __pycache__/.pytest_cache in the mounted worktree,
# which then could not be removed without sudo.
BACKEND_IMAGE ?= goalgetter-backend-planning-backend
DOCKER_RUN    := docker run --rm --network host --user "$$(id -u):$$(id -g)" \
                 -e HOME=/tmp -e PYTHONDONTWRITEBYTECODE=1 \
                 -v "$(CURDIR)":/app -w /app $(BACKEND_IMAGE)

.DEFAULT_GOAL := help

.PHONY: help check backend frontend back-lint back-test front-lint front-test setup hooks env test-db claude-token shot preview preview-down claude

help: ## Show this help
	@grep -hE '^[a-z][a-z0-9-]*:.*?## ' $(MAKEFILE_LIST) \
	  | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

check: backend frontend ## Run every gate (backend + frontend)

backend: back-lint back-test ## Backend: house lint + pytest

frontend: front-lint front-test ## Frontend: line limits + analyze + tests

back-lint: ## Backend house rules (file/endpoint/test length, repository pattern)
	@python3 backend/tests/backend_linter.py

back-test: env ## Backend pytest (needs the test database: docker compose up -d postgres_test)
	@$(DOCKER_RUN) python -m pytest backend/tests -o addopts="" -q -p no:cacheprovider

front-lint: ## Frontend dart line limits + flutter analyze
	@cd frontend && $(DART) run tool/frontend_linter.dart
	@cd frontend && $(FLUTTER) analyze --no-fatal-infos --no-fatal-warnings

front-test: ## Frontend widget/unit tests
	@cd frontend && $(FLUTTER) test

env: ## Seed this worktree's .env from the main checkout (never overwrites)
	@if [ -f .env ]; then :; else \
	  main="$$(git worktree list --porcelain | awk '/^worktree /{print $$2; exit}')"; \
	  if [ -f "$$main/.env" ]; then cp "$$main/.env" .env && echo "seeded .env from $$main"; \
	  else echo "no .env here and none in $$main - backend tests will fail"; fi; \
	fi

# The test fixtures drop every table at session start and end, so two worktrees
# sharing one test database wipe each other mid-run. Each linked worktree gets its
# own (goalgetter_test_<dir>); the main checkout keeps goalgetter_test. Only the
# password-free tail of TEST_DATABASE_URL is rewritten, and nothing is printed.
test-db: env ## Give this worktree its own test database and point .env at it
	@main="$$(git worktree list --porcelain | awk '/^worktree /{print $$2; exit}')"; \
	if [ "$$main" = "$(CURDIR)" ]; then db=goalgetter_test; \
	else db="goalgetter_test_$$(basename "$(CURDIR)" | tr 'A-Z' 'a-z' | tr -c 'a-z0-9\n' '_')"; fi; \
	docker exec goalgetter_postgres_test psql -U postgres -Atc "SELECT 1 FROM pg_database WHERE datname='$$db'" | grep -q 1 \
	  || docker exec goalgetter_postgres_test createdb -U postgres "$$db"; \
	sed -i -E "s#^(TEST_DATABASE_URL=\"?[^\"]*/)[^/\"]*(\"?)\$$#\1$$db\2#" .env; \
	echo "test database: $$db"

setup: hooks env test-db ## One-time per checkout/worktree: git hooks + .env + own test DB + frontend deps
	@cd frontend && $(FLUTTER) pub get

hooks: ## Point git at the versioned hooks in .githooks
	@git config core.hooksPath .githooks
	@echo "core.hooksPath -> .githooks"

# A bearer for "Fictitious Claude", so Claude can drive the API without Google.
# Needs a running backend started with DEV_LOGIN=true (off, the route is a 404).
# Only the access token is written, with no trailing newline, so
# `$(cat .claude/token)` drops straight into an Authorization header.
BACKEND_PORT ?= 8001
claude-token: ## Sign in as "Fictitious Claude" on the running backend and write .claude/token
	@url="http://127.0.0.1:$(BACKEND_PORT)/api/v1/auth/dev-login"; \
	body="$$(curl -fsS -X POST "$$url" -H 'Content-Type: application/json' -d '{"name": "Claude"}')" \
	  || { echo "claude-token: POST $$url failed. Is the backend up on $(BACKEND_PORT) (BACKEND_PORT=...) with DEV_LOGIN=true?" >&2; exit 1; }; \
	mkdir -p .claude; umask 077; \
	printf '%s' "$$body" | python3 -c 'import json,sys; sys.stdout.write(json.load(sys.stdin)["access_token"])' > .claude/token; \
	echo "claude-token: wrote .claude/token for Fictitious Claude."; \
	echo "  It expires in 30 minutes, and dies with any backend restart (the database is dropped on start): re-run then."; \
	echo "  curl -H \"Authorization: Bearer \$$(cat .claude/token)\" http://127.0.0.1:$(BACKEND_PORT)/api/v1/..."

# --- Looking at the app ------------------------------------------------------
# The preview is the integrated app for a phone on the tailnet: the release web
# build and the API on one origin, served by nginx on loopback and this machine's
# Tailscale address only (tools/preview/nginx.conf). It lives outside every
# worktree, so removing a worktree never takes it down. The backend reads the
# main checkout's .env (mounted read-only, never copied) and drops its schema on
# every start, like any backend here - a rebuild signs everyone out.
PREVIEW_DIR  ?= $(HOME)/.local/share/goalgetter-preview
PREVIEW_PORT := 8093
MAIN_CHECKOUT = $(shell git worktree list --porcelain | awk '/^worktree /{print $$2; exit}')

preview: ## Build and serve the integrated app on the tailnet (http://<this host>:8093)
	@set -e; \
	ip="$$(tailscale ip -4 | head -n1)"; [ -n "$$ip" ] || { echo "tailscale is not up"; exit 1; }; \
	mkdir -p "$(PREVIEW_DIR)"; \
	docker build -q -t goalgetter-preview-backend backend >/dev/null; \
	docker rm -f goalgetter_preview_backend >/dev/null 2>&1 || true; \
	docker run -d --name goalgetter_preview_backend --network host --restart unless-stopped \
	  -v "$(MAIN_CHECKOUT)/.env":/app/.env:ro -e DEV_LOGIN=true goalgetter-preview-backend \
	  uvicorn backend.main:app --host 127.0.0.1 --port 8001 --workers 1 >/dev/null; \
	(cd frontend && $(FLUTTER) build web --release --dart-define=DEV_LOGIN=true --dart-define=BASE_URL= \
	  --output "$(PREVIEW_DIR)/web"); \
	sed "s/__TAILNET_IP__/$$ip/" tools/preview/nginx.conf > "$(PREVIEW_DIR)/nginx.conf"; \
	docker rm -f goalgetter_preview >/dev/null 2>&1 || true; \
	docker run -d --name goalgetter_preview --network host --restart unless-stopped \
	  -v "$(PREVIEW_DIR)/web":/usr/share/nginx/html:ro -v "$(PREVIEW_DIR)/nginx.conf":/etc/nginx/conf.d/default.conf:ro \
	  nginx:alpine >/dev/null; \
	host="$$(tailscale status --json | python3 -c 'import json,sys;print(json.load(sys.stdin)["Self"]["DNSName"].rstrip("."))')"; \
	echo "preview: http://$$host:$(PREVIEW_PORT)  (tailnet only)"

preview-down: ## Stop the tailnet preview (web + its backend)
	@docker rm -f goalgetter_preview goalgetter_preview_backend >/dev/null 2>&1; echo "preview stopped"

# `make shot ROUTES="/home /goals"` writes one phone-sized PNG per route to
# shots/, signed in with .claude/token when it exists (make claude-token).
ROUTES ?= /
shot: ## Headless phone screenshots of ROUTES from the preview, into shots/
	@node tools/shot.mjs --url http://127.0.0.1:$(PREVIEW_PORT) --out shots \
	  $(if $(wildcard .claude/token),--token .claude/token) $(ROUTES)

# `make claude`: "Fictitious Claude" with a lived-in history, so every signed-in
# screen has data (backend/services/fictitious/, hardcoded, no Gemini/YouTube),
# then its token through `claude-token`. It writes to DATABASE_URL: the
# environment's if set (forwarded by name, never echoed), else .env's, which is
# the dev database the preview backend uses. The schema must exist (a backend
# creates it on start), and every backend start drops it: re-run after one.
# Idempotent; ARGS=--fresh deletes the student and rebuilds it.
CLAUDE_RUN = $(subst --network host,--network host $(if $(DATABASE_URL),-e DATABASE_URL),$(DOCKER_RUN))
claude: env ## Seed "Fictitious Claude" with a lived-in history, then write .claude/token (ARGS=--fresh)
	@$(CLAUDE_RUN) python -m backend.services.fictitious $(ARGS)
	@$(MAKE) --no-print-directory claude-token
