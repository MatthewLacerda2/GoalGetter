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
# The same container, forwarding DATABASE_URL by NAME (never a value on a
# command line, where `ps` would read it). With none in the environment the
# container falls back to the .env it has mounted, which is this worktree's.
# `migrate` and `claude` both target a database, so both run through this.
DOCKER_RUN_DB := $(subst --network host,--network host -e DATABASE_URL,$(DOCKER_RUN))

# Every Python tool - ruff, vulture, the build smoke, pytest - runs inside the
# backend image, because there is no local venv here. CI has no image: it
# pip-installs backend/requirements.txt onto the runner and overrides these with
# `make back-lint PY=python PY_OFFLINE=python`.
PY         ?= $(DOCKER_RUN) python
PY_OFFLINE ?= $(DOCKER_RUN_OFFLINE) python
# The live suite's container forwards the two API keys by NAME, like
# DOCKER_RUN_DB: unset here, the container reads them from the mounted .env; set
# (even empty, `GEMINI_API_KEY= make test-live`), the environment wins. CI
# overrides it with `PY_LIVE=python`, the keys arriving from its secrets.
PY_LIVE    ?= $(subst --network host,--network host -e GEMINI_API_KEY -e YOUTUBE_API_KEY,$(DOCKER_RUN)) python

.DEFAULT_GOAL := help

.PHONY: help check backend frontend gen-l10n back-lint back-fix back-deadcode back-build back-migrations back-revision back-test back-image migrate front-version front-lint front-test setup hooks env test-db claude-token shot preview preview-down claude gemini nightly embeddings test-live

help: ## Show this help
	@grep -hE '^[a-z][a-z0-9-]*:.*?## ' $(MAKEFILE_LIST) \
	  | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

check: backend frontend ## Run every gate (backend + frontend)

backend: back-lint back-deadcode back-build back-migrations back-test ## Backend: lint + dead code + build smoke + migrations + pytest

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

# In `make backend` rather than beside it, because it is the same failure the
# other gates are for: the tests build their tables from the models, so a model
# changed without a migration is green here and broken on deploy. It needs a
# database - the worktree's own test one, which it resets - and `back-test`
# already needed that, so the gate adds a prerequisite nobody has to think
# about. It runs before pytest only because it is the cheaper of the two.
back-migrations: env ## Backend schema gate: the migrations build it from empty, and match the models
	@$(PY) -m backend.tools.migration_check

# The fix for a red back-migrations, not a gate: autogenerate the revision the
# models are asking for. A generated revision is a draft - read it.
back-revision: env ## Draft a migration from the models (M="what changed")
	@[ -n "$(M)" ] || { echo 'usage: make back-revision M="what changed"'; exit 1; }
	@$(PY) -m backend.tools.migration_check --revision "$(M)"

back-test: env ## Backend pytest (needs the test database: docker compose up -d postgres_test)
	@$(PY) -m pytest backend/tests -o addopts="" -q -p no:cacheprovider

# Every backend gate runs in this image, so an image older than
# backend/requirements.txt fails with a bare "No module named ruff". Rebuilding
# is a plain `docker build` - it starts nothing.
back-image: ## Rebuild the backend image the gates run in (after a requirements.txt change)
	@docker build -t $(BACKEND_IMAGE) backend

# One number, one meaning. `environment.flutter` in frontend/pubspec.yaml is the
# pin, and CI installs exactly it - but pub reads the same line as a floor
# (`>=`), so the two ends disagree. A machine BEHIND the pin fails `pub get`
# loudly, with both numbers in the message; a machine AHEAD of it is silent, and
# then the branch is green here having been analyzed by a version that will
# never judge it (#147 - #119's drift, inverted).
#
# This makes the silent direction behave like the loud one: the gate refuses to
# call itself green when the analyzer it just ran is not the one CI will run.
# It is a comparison of two strings - ~0.5s, and nothing when they agree - and
# both frontend gates depend on it, so make runs it once per `make frontend`.
# CI runs it too, where the same comparison doubles as the assertion that
# flutter-action installed the version the pin asked for.
front-version: ## Check this machine's Flutter is exactly frontend/pubspec.yaml's pin
	@pin="$$(sed -nE 's/^[[:space:]]+flutter:[[:space:]]*([0-9][^[:space:]#]*).*/\1/p' frontend/pubspec.yaml | head -n1)"; \
	have="$$($(FLUTTER) --version 2>/dev/null | sed -nE 's/^Flutter ([^[:space:]]+).*/\1/p' | head -n1)"; \
	if [ -z "$$pin" ] || [ -z "$$have" ] || [ "$$have" = "0.0.0-unknown" ]; then \
	  echo "→ Flutter pin check skipped (read pin='$$pin' sdk='$$have')"; \
	elif [ "$$pin" != "$$have" ]; then \
	  echo "Flutter $$have is installed here; frontend/pubspec.yaml pins $$pin."; \
	  echo "CI installs the pin exactly, so this analyzer is not the one that will judge the branch."; \
	  echo "Fix one line: 'flutter: $$have' in frontend/pubspec.yaml, or put this SDK back on $$pin."; \
	  exit 1; \
	fi

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

front-lint: front-version gen-l10n ## Frontend dart line limits + flutter analyze
	@cd frontend && $(DART) run tool/frontend_linter.dart
	@cd frontend && $(FLUTTER) analyze --no-fatal-infos

front-test: front-version gen-l10n ## Frontend widget/unit tests
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
	@git config blame.ignoreRevsFile .git-blame-ignore-revs
	@echo "blame.ignoreRevsFile -> .git-blame-ignore-revs"

# `make migrate`: bring DATABASE_URL's database to the current head. Nothing
# creates the schema on start any more (#157), so this is how a database gets
# one - the compose stack runs the same command as its own `migrate` service.
# Useful ARGS:
#   ARGS='stamp head'                a database whose tables were built by the
#                                    old startup path: record it as already at
#                                    head instead of building it again
#   ARGS='downgrade base' then bare  a clean database, the reset that starting
#                                    the backend used to give away
#   ARGS=current / ARGS=history      where this database is, and what there is
migrate: env ## Apply migrations to DATABASE_URL (ARGS='stamp head', 'downgrade base', 'current', ...)
	@$(DOCKER_RUN_DB) python -m alembic -c backend/alembic.ini $(if $(ARGS),$(ARGS),upgrade head)

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
	echo "  It expires in 30 minutes: re-run then. A backend restart no longer costs it (#157)."; \
	echo "  curl -H \"Authorization: Bearer \$$(cat .claude/token)\" http://127.0.0.1:$(BACKEND_PORT)/api/v1/..."

# --- Looking at the app ------------------------------------------------------
# The preview is the integrated app for a phone on the tailnet: the release web
# build and the API on one origin, served by nginx on loopback and this machine's
# Tailscale address only (tools/preview/nginx.conf). It lives outside every
# worktree, so removing a worktree never takes it down. The backend reads the
# main checkout's .env (mounted read-only, never copied).
#
# Since #157 it no longer wipes anything: the recipe runs `migrate` on the
# preview database and starts a backend that creates no schema, so a rebuild
# keeps the students that were in there. (It used to drop its schema on every
# start, which is why `make claude` exists.)
#
# It has its OWN database (#122). The preview used to take DATABASE_URL straight
# from that .env, which is the shared dev database, so every `make preview`
# wiped whatever anyone else had in there - the one thing left sharing after the
# test databases were split per worktree (#64). The preview now gets
# goalgetter_preview, created the way `make test-db` creates its own: a database
# on the dev server, so the URL is the dev one with the name swapped and no new
# credential exists anywhere. It is read out of .env inside the recipe, handed
# to the container by name (`-e DATABASE_URL`, never a value on a command line)
# and never printed. The rest of .env - the Gemini key, the OAuth client -
# still comes from the mount.
PREVIEW_DIR  ?= $(HOME)/.local/share/goalgetter-preview
PREVIEW_PORT := 8093
PREVIEW_DB   := goalgetter_preview

# What the preview build is compiled with. The default is the dev sign-in,
# which is the point of the preview: no Google, no real account. `make preview
# PREVIEW_DEFINES=` builds what a visitor gets instead - Google's own sign-in
# button and nothing else - which is the only way to look at that screen (#84).
PREVIEW_DEFINES ?= --dart-define=DEV_LOGIN=true
MAIN_CHECKOUT = $(shell git worktree list --porcelain | awk '/^worktree /{print $$2; exit}')
# Prints the preview's DATABASE_URL on stdout: the dev server's, with the
# database name replaced. Both `preview` and `claude` read it this way.
# The sed delimiter is `|`, not `#`: a `#` here would start a make comment and
# silently truncate the command.
PREVIEW_URL = sed -nE 's|^DATABASE_URL="?([^"]*)"?$$|\1|p' "$(MAIN_CHECKOUT)/.env" \
	  | head -n1 | sed -E 's|/[^/]*$$|/$(PREVIEW_DB)|'

preview: ## Build and serve the integrated app on the tailnet (http://<this host>:8093)
	@set -e; \
	ip="$$(tailscale ip -4 | head -n1)"; [ -n "$$ip" ] || { echo "tailscale is not up"; exit 1; }; \
	export DATABASE_URL="$$($(PREVIEW_URL))"; \
	[ -n "$$DATABASE_URL" ] || { echo "preview: no DATABASE_URL in $(MAIN_CHECKOUT)/.env"; exit 1; }; \
	docker exec goalgetter_postgres psql -U postgres -Atc "SELECT 1 FROM pg_database WHERE datname='$(PREVIEW_DB)'" | grep -q 1 \
	  || docker exec goalgetter_postgres createdb -U postgres "$(PREVIEW_DB)"; \
	$(MAKE) --no-print-directory migrate; \
	mkdir -p "$(PREVIEW_DIR)"; \
	docker build -q -t goalgetter-preview-backend backend >/dev/null; \
	docker rm -f goalgetter_preview_backend >/dev/null 2>&1 || true; \
	docker run -d --name goalgetter_preview_backend --network host --restart unless-stopped \
	  -v "$(MAIN_CHECKOUT)/.env":/app/.env:ro -e DEV_LOGIN=true -e DATABASE_URL goalgetter-preview-backend \
	  uvicorn backend.main:app --host 127.0.0.1 --port 8001 --workers 1 >/dev/null; \
	(cd frontend && $(FLUTTER) build web --release $(PREVIEW_DEFINES) --dart-define=BASE_URL= \
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
#
# A signed-in session is a token AND an active goal, and the app only writes
# the goal down when it boots through `/`: a deep link to /lesson photographed
# the "no active goal" empty state however much the student had (#127). With
# no GOAL the tool asks the API which goal is active, so the usual call needs
# nothing extra; `make shot GOAL=<id>` photographs another of the student's.
ROUTES ?= /
shot: ## Headless phone screenshots of ROUTES from the preview, into shots/ (GOAL=<id> picks the goal, SCHEME=dark the phone's mode)
	@node tools/shot.mjs --url http://127.0.0.1:$(PREVIEW_PORT) --out shots \
	  $(if $(wildcard .claude/token),--token .claude/token) $(if $(GOAL),--goal $(GOAL)) $(if $(SCHEME),--scheme $(SCHEME)) $(ROUTES)

# `make gemini`: run ONE Gemini use case for real and print the raw text next to
# the parsed object (backend/tools/gemini_cli.py). It SPENDS REAL QUOTA on the
# project's key - one run, one billed call (the resource search: two, plus one
# embedding per resource recommended) - so it is never wired into a gate and
# never called from the default suite. With no ARGS it lists the use cases it
# knows and spends nothing.
#   make gemini
#   make gemini ARGS='tutor-reply "Chess" "Learn chess openings" "How do I start?"'
gemini: env ## Run one Gemini use case for real (SPENDS QUOTA; no ARGS lists them)
	@$(DOCKER_RUN) python -m backend.tools.gemini_cli $(ARGS)

# `make test-live`: the live suite (#176) - one real call per Gemini use case,
# the embedding batch, the resource search through link validation, and one
# YouTube search. It asserts contracts, never words, and prints how many calls
# it made. It SPENDS REAL QUOTA, so no gate depends on it: `make check` and the
# every-push CI skip these tests, and the default suite fails any test that
# reaches the network at all. Ask the user before running it.
test-live: env ## The live suite against the real Gemini and YouTube APIs (SPENDS QUOTA)
	@$(PY_LIVE) -m pytest backend/tests/live --live -o addopts="" -q -rs -p no:cacheprovider

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
# environment's if set, else the preview's own database (#122) - the one the
# backend on BACKEND_PORT is serving. Either way it is forwarded by name and
# never echoed. A backend run by hand against another database wants that
# database named: `DATABASE_URL=... make claude`. The schema must exist
# (`make migrate`); since #157 nothing drops it, so this survives a restart and
# only has to be run once. Idempotent; ARGS=--fresh deletes the student and
# rebuilds it.
claude: env ## Seed "Fictitious Claude" with a lived-in history, then write .claude/token (ARGS=--fresh)
	@set -e; export DATABASE_URL="$${DATABASE_URL:-$$($(PREVIEW_URL))}"; \
	[ -n "$$DATABASE_URL" ] || { echo "claude: no DATABASE_URL in $(MAIN_CHECKOUT)/.env"; exit 1; }; \
	$(DOCKER_RUN_DB) python -m backend.services.fictitious $(ARGS)
	@$(MAKE) --no-print-directory claude-token
