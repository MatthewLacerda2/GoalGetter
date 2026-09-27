#!/usr/bin/env bash
# A Postgres that exists for one run of a backend gate, and not a second longer (#205).
#
#   tools/test-db.sh <container name> <command...>
#
# Starts `pgvector/pgvector:pg18` - the image the stack runs, so no pull - with its
# data on a tmpfs, exports TEST_DATABASE_URL pointing at it, runs the command, and
# removes the container by name however the command ends: success, failure,
# Ctrl-C, a TERM or a closed terminal. Nothing is written to disk, no volume is
# created, and the name carries the worktree and a random tail, so two worktrees -
# or two runs in one - never meet. The command gets an empty database: the pytest fixtures migrate it
# (`alembic upgrade head`), `backend.tools.migration_check` builds it the same way.
#
# TEST_DB_MODE picks how the command reaches it:
#
#   isolated (default)  The container has no network at all (`--network none`),
#                       and the command is expected to be a container that joins
#                       its namespace (`--network container:<name>`, see
#                       DOCKER_RUN_TESTDB in the Makefile). Inside, 127.0.0.1:5432
#                       is this database and there is nothing else: not the host's
#                       5434, not the internet, not DNS. The tests cannot reach the
#                       live database because no route to it exists.
#   published           CI, where the command is the runner's own python. The port
#                       is published on 127.0.0.1 at one Docker picks, so parallel
#                       runs never collide. The runner holds no live database; the
#                       in-process guard (backend/tests/fixtures/network.py) is what
#                       confines the tests there.
#
# DATABASE_URL is exported as the same test URL, so nothing this command runs
# holds the real one even by accident (the pytest process then replaces it with a
# host that cannot resolve - see network.py). The password is random per run, and
# both URLs are handed on by name, never on a command line.
set -euo pipefail

name="${1:?usage: tools/test-db.sh <container name> <command...>}"
shift
image="${TEST_DB_IMAGE:-pgvector/pgvector:pg18}"
mode="${TEST_DB_MODE:-isolated}"

# From the first line on, so a Ctrl-C while the database is still starting
# removes it too. A signal ends the command first, then the script; EXIT removes
# both containers, which is what actually stops a command running inside one.
child=''
cleanup() { docker rm -f "$name" "${name}_run" >/dev/null 2>&1 || true; }
on_signal() {
  [ -n "$child" ] && kill "$child" 2>/dev/null
  exit "$1"
}
trap cleanup EXIT
trap 'on_signal 129' HUP
trap 'on_signal 130' INT
trap 'on_signal 143' TERM

# The one ending no trap sees is a SIGKILL. Every container carries the pid of the
# script that owns it, so the next run anywhere removes those whose owner is gone -
# by name, never by pattern, and never one whose owner is still alive.
docker ps -a --filter label=goalgetter.testdb.owner \
  --format '{{.Names}} {{.Label "goalgetter.testdb.owner"}}' |
  while read -r stale owner; do
    [ -d "/proc/$owner" ] || docker rm -f "$stale" "${stale}_run" >/dev/null 2>&1 || true
  done

case "$mode" in
  isolated) network=(--network none) ;;
  published) network=(-p 127.0.0.1::5432) ;;
  *) echo "TEST_DB_MODE must be isolated or published, not '$mode'" >&2; exit 2 ;;
esac

POSTGRES_PASSWORD="$(head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n')"
export POSTGRES_PASSWORD

# fsync and friends off: the data is thrown away at the end, so durability buys
# nothing and costs seconds.
docker run -d --rm --name "$name" --label goalgetter.testdb.owner=$$ "${network[@]}" \
  --tmpfs /var/lib/postgresql \
  -e POSTGRES_PASSWORD -e POSTGRES_DB=goalgetter_test "$image" \
  -c fsync=off -c synchronous_commit=off -c full_page_writes=off >/dev/null

port=5432
if [ "$mode" = published ]; then
  port="$(docker port "$name" 5432/tcp | head -n1 | sed 's/.*://')"
fi

# Over TCP: the image's first boot runs a temporary server on the unix socket
# only, and it would pass a socket check just before shutting down.
ready=''
for _ in $(seq 120); do
  if docker exec "$name" pg_isready -q -h 127.0.0.1 -U postgres -d goalgetter_test; then
    ready=1
    break
  fi
  sleep 0.25
done
if [ -z "$ready" ]; then
  echo "test database $name did not come up in 30s:" >&2
  docker logs --tail 20 "$name" >&2 || true
  exit 1
fi

TEST_DATABASE_URL="postgresql+asyncpg://postgres:${POSTGRES_PASSWORD}@127.0.0.1:${port}/goalgetter_test"
DATABASE_URL="$TEST_DATABASE_URL"
export TEST_DATABASE_URL DATABASE_URL
unset POSTGRES_PASSWORD

# In the background and waited for, so a signal reaches the trap at once rather
# than after the whole suite.
"$@" &
child=$!
wait "$child"
