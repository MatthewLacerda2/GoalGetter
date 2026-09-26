#!/usr/bin/env bash
# Bring production up to origin/main (#105). Run every two minutes by the
# goalgetter-deploy user timer (`make deploy-install`), or once by `make deploy`.
# It does nothing when the live commit already is main.
#
# Why a timer that pulls, not a GitHub Actions runner: the repository is public,
# and a self-hosted runner on a public repo runs whatever a fork's pull request
# asks of it, on this machine. Polling needs no inbound access and no token
# beyond what `git fetch` already uses.
#
# Why no CI check here: CI runs on pull requests, and nothing reaches main except
# through a merged one - a commit on main has already passed its gate.
#
# A failed build leaves the running containers alone: `build` is its own step and
# `up` only follows once every image built. The failed commit is remembered so the
# timer does not rebuild it every two minutes; the next commit on main is tried
# normally. A failed *migration* is different: `migrate` exits non-zero, the
# backend waits for it, and the site stays down until a fix lands - which is what
# docker-compose.yml says should happen.
set -euo pipefail

repo="$(git -C "$(dirname "$(readlink -f "$0")")" worktree list --porcelain | awk '/^worktree /{print $2; exit}')"
cd "$repo"
state="$repo/.deploy"
mkdir -p "$state"
exec 9>"$state/lock"
flock -n 9 || { echo "deploy: another run holds the lock"; exit 0; }

log() { echo "deploy: $*"; }

[ "$(git rev-parse --abbrev-ref HEAD)" = main ] || { log "main checkout is not on main - skipping"; exit 0; }
git diff --quiet && git diff --cached --quiet || { log "main checkout has local changes - skipping"; exit 0; }

git fetch -q origin main
target="$(git rev-parse origin/main)"
[ "$target" != "$(cat "$state/live" 2>/dev/null || true)" ] || exit 0
[ "$target" != "$(cat "$state/failed" 2>/dev/null || true)" ] || exit 0

git merge -q --ff-only origin/main
log "building $(git log --oneline -1 "$target")"
if ! docker compose build; then
  echo "$target" > "$state/failed"
  log "build FAILED for $target - the previous version keeps running"
  exit 1
fi
docker compose up -d --remove-orphans
echo "$target" > "$state/live"
rm -f "$state/failed"
log "live: $(git log --oneline -1 "$target")"
