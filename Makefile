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

.PHONY: help check backend frontend back-lint back-test front-lint front-test setup hooks env

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

setup: hooks env ## One-time per checkout/worktree: git hooks + .env + frontend deps
	@cd frontend && $(FLUTTER) pub get

hooks: ## Point git at the versioned hooks in .githooks
	@git config core.hooksPath .githooks
	@echo "core.hooksPath -> .githooks"
