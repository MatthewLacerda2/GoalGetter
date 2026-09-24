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
# The same container cut off from the network. `back-build` claims it needs no
# database; with no network it could not reach one even if the claim were wrong.
DOCKER_RUN_OFFLINE := $(subst --network host,--network none,$(DOCKER_RUN))

# Every Python tool - ruff, vulture, the build smoke, pytest - runs inside the
# backend image, because there is no local venv here. CI has no image: it
# pip-installs backend/requirements.txt onto the runner and overrides these with
# `make back-lint PY=python PY_OFFLINE=python`.
PY         ?= $(DOCKER_RUN) python
PY_OFFLINE ?= $(DOCKER_RUN_OFFLINE) python

.DEFAULT_GOAL := help

.PHONY: help check backend frontend gen-l10n back-lint back-fix back-deadcode back-build back-test back-image front-lint front-test setup hooks env test-db claude-token shot preview preview-down claude gemini nightly embeddings

help: ## Show this help
	@grep -hE '^[a-z][a-z0-9-]*:.*?## ' $(MAKEFILE_LIST) \
	  | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

check: backend frontend ## Run every gate (backend + frontend)

backend: back-lint back-deadcode back-build back-test ## Backend: lint + dead code + build smoke + pytest

frontend: front-lint front-test ## Frontend: line limits + analyze + tests

# Cheapest first: the house rules are stdlib and instant, ruff is a second, the
# build smoke needs no database, and only pytest needs one.
back-lint: ## Backend lint: house rules (file/endpoint/test length, repositories) + ruff check + ruff format --check
	@python3 backend/tests/backend_linter.py
	@$(PY) -m ruff check backend
	@$(PY) -m ruff format --check backend

# A fixer, not a gate: `ruff check --fix` exits non-zero when findings remain
# that it cannot fix, and the formatter should still run. back-lint is the gate.
back-fix: ## Auto-fix exactly what back-lint checks (ruff check --fix + ruff format)
	@-$(PY) -m ruff check --fix backend
	@$(PY) -m ruff format backend

back-deadcode: ## Backend whole-program dead-code gate (vulture; whitelist in backend/tools/deadcode.py)
	@$(PY) -m backend.tools.deadcode

back-build: ## Backend build smoke: import the app and generate the OpenAPI (no database)
	@$(PY_OFFLINE) -m backend.tools.build_smoke

back-test: env ## Backend pytest (needs the test database: docker compose up -d postgres_test)
	@$(PY) -m pytest backend/tests -o addopts="" -q -p no:cacheprovider

# Every backend gate runs in this image, so an image older than
# backend/requirements.txt fails with a bare "No module named ruff". Rebuilding
# is a plain `docker build` - it starts nothing.
back-image: ## Rebuild the backend image the gates run in (after a requirements.txt change)
	@docker build -t $(BACKEND_IMAGE) backend

# A warning fails this gate (#101): the backlog that justified letting them
# through is gone. The infos are a separate, larger backlog, so they still
# only report.
# The ARB files generate lib/l10n/generated/, which is gitignored - so it is
# whatever the last branch in this worktree left behind. A branch that adds or
# renames a key leaves it stale, and then every frontend gate fails on getters
# that do exist (seen on `main` 2026-09-24 after #119 and #124: 12 undefined_getter
# errors, zero of them real). CI never sees it, because a fresh checkout's
# `flutter pub get` regenerates - so the gate lies only on the machine where the
# work happens. Regenerating first costs a couple of seconds and removes the
# whole class.
gen-l10n: ## Regenerate lib/l10n/generated/ from the ARB files
	@cd frontend && $(FLUTTER) gen-l10n

front-lint: gen-l10n ## Frontend dart line limits + flutter analyze
	@cd frontend && $(DART) run tool/frontend_linter.dart
	@cd frontend && $(FLUTTER) analyze --no-fatal-infos

front-test: gen-l10n ## Frontend widget/unit tests
	@cd frontend && $(FLUTTER) test

# On a runner there is no main checkout to copy from, and the settings arrive as
# real environment variables from the workflow - so having no .env is correct
# there, not a warning.
env: ## Seed this worktree's .env from the main checkout (never overwrites)
	@if [ -f .env ] || [ -n "$$DATABASE_URL" ]; then :; else \
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

# `make gemini`: run ONE Gemini use case for real and print the raw text next to
# the parsed object (backend/tools/gemini_cli.py). It SPENDS REAL QUOTA on the
# project's key - one run, one billed call (the resource search: three) - so it
# is never wired into a gate and never called from the tests. With no ARGS it
# lists the use cases it knows and spends nothing.
#   make gemini
#   make gemini ARGS='tutor-reply "Chess" "Learn chess openings" "How do I start?"'
gemini: env ## Run one Gemini use case for real (SPENDS QUOTA; no ARGS lists them)
	@$(DOCKER_RUN) python -m backend.tools.gemini_cli $(ARGS)

# `make nightly ARGS='--student <id>'`: the nightly run (#89) by hand, now,
# instead of at 03:00, logging every decision it takes - which students it
# skips and why, and which steps it asks for. `--once` does the whole night.
# It runs the real job against DATABASE_URL and SPENDS REAL QUOTA; in the
# deployment the same entry point is the `nightly` compose service.
nightly: env ## Run the nightly job by hand (SPENDS QUOTA; ARGS='--student <id>' or --once)
	@$(DOCKER_RUN) python -m backend.tools.nightly_run $(ARGS)

# `make embeddings`: the embedding backfill (#96) by hand, now, instead of at
# midnight - every null vector in the seven columns, in batch, logging how many
# rows each column had, how many it filled and how many it left. Same entry
# point and same compose service as `nightly`, and it SPENDS REAL QUOTA (one
# billed call per hundred texts). Safe to repeat: null is the only queue, so a
# second run finds only what the first did not fill.
embeddings: env ## Fill every null embedding by hand (SPENDS QUOTA)
	@$(DOCKER_RUN) python -m backend.tools.nightly_run --embeddings

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
