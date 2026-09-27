---
name: issue-batch
description: Work several issues at once in this repo, typically unattended overnight — how many agents to run, which files collide, when a green gate is lying, what must never be touched, and how to brief a subagent. Use when starting more than one branch, when spawning subagents, when the user asks for a batch of ready issues to be worked, or when new work is being dictated faster than one branch can absorb it.
---

# Working several issues at once

The user plans several issues during the day and hands the ready ones over at night:
Claude works them while he sleeps. So a batch runs with **nobody to ask** — every rule
below exists because there is no one to catch the mistake until morning.

## One issue, one worktree, one agent

The default shape: **an issue gets its own worktree and its own agent**. That is what
keeps two branches from taking turns in one checkout, and what makes a red gate mean
something.

Folding several issues into one agent is **allowed, never required**. Fold when they
touch the same files, or when one is too small to be worth a branch of its own — that
is exactly what **`minor`** marks: a change of about thirty lines that may ride along
in another issue's pull request. An agent that folds says so in the PR, which then
closes each issue it finished.

**An issue that carries a migration gets a database of its own** if it needs a running
backend: it is about to change a schema every other worktree is reading. The gates need
nothing: `make back-migrations` and `make back-test` each start a disposable database for
the run (#205), which is where a migration is proven.

## What a batch is allowed to pick up

Only **ready** issues: open, with **no** `planning` and **no** `human` label (see
`issue-write`). An issue with a stage label is never started, however startable it
looks. An issue that turns out, once read, to need a decision nobody made is not
guessed at — its PR goes up as a **draft** naming the question, and the batch moves on.

Order the merges by priority — `architecture` → `infrastructure` → `bug` →
`foundation` → `feature`, `documentation` any time — and respect **Blocked by**: a
blocked issue waits until its blocker has merged.

## The bottleneck is the machine, not the merge queue

`make check` is quick and a rebase is a small merge. What does not scale is CPU: Flutter
analyze and test runs, and the backend tests in Docker, are heavy, and several at once
will bury this machine. A buried machine makes the gates **lie** — tests time out
competing for a core and go red over nothing in the diff.

- **At most five worktrees at once** (the user, 2026-09-27). The limit counts worktrees,
  not agents or issues: one agent may fold several issues into one, and a finished
  agent's worktree still counts until it is removed. Disk and conflicts are why. So a
  worktree is removed by name as soon as its pull request merges
  or no longer needs it, and only then is the next one created.
- **At most two agents running Flutter gates at the same time**, inside those five. A
  third is not faster; it makes all three untrustworthy.
- **A red gate under load is re-run, not believed.** Check `uptime` first; once load is
  near the core count, the result means nothing either way.
- Do not write down how long a gate takes. It depends on the machine and on what else
  runs; measure it when it matters.

## The files where everything collides

Two agents in different areas rarely conflict. Two agents in any of these will. **This
list is derived from the structure, not yet from observed conflicts** — replace an entry
with the real reason the first time it actually bites.

| file | why |
| --- | --- |
| `frontend/lib/l10n/app_*.arb` (all five) | JSON: every new string is appended, and each append must add a comma to the **same** previous last line — two branches adding a string always conflict, in five files at once |
| `frontend/lib/app/router/app_router.dart`, `app_routes.dart` | every screen registers its route here |
| `frontend/lib/app/dev/dev_menu_screen.dart`, `dev_fixtures.dart` | every screen gets a dev-menu entry |
| `backend/api/v1/endpoints/__init__.py` | every router registers here |
| `backend/api/v1/endpoints/<resource>.py` | endpoints sharing a prefix share one module, and most still to build hang off `/goals` |
| `backend/models/__init__.py` | every model registers here |
| `frontend/docs/backend_contract.md` | every endpoint's status is recorded here |

**Name the siblings and their files in every brief.** An agent told which files belong
to somebody else keeps its diff out of them.

## The house lint fires on the sum

The 350-line ceiling can be broken by two branches that each pass alone. **So the gate
that matters runs on the merge, not on the branch**: merge everything locally, run
`make check`, and only then push. When it fires there is usually a real seam underneath
— split along meaning, never trim comments to fit (comments are free anyway).

## What a batch must never touch

- **Docker state it did not create.** `docker builder prune`, `docker system prune`, or
  removing an image, volume or cache not made by that agent under its own name: the build
  cache and images are shared with production. An agent "cleaning up after itself" with a
  time-filtered prune deleted 16.75 GB of cache on 2026-09-26 (#192) — nothing broke, the
  next production build just started cold. Clean up by name, never by filter.
- **The shared dev database.** Every worktree points at the same dev database, and a
  subagent that migrates it, seeds it or downgrades it changes the data of whoever else
  is using it. (Nothing drops the schema on start any more since #157 — that is not a
  licence to use it.) The tailnet preview is no
  longer one of them: since #122 it has a database of its own, and `make preview`
  leaves the dev one alone. Backend work is validated by `make back-test`,
  which starts a disposable database for each run and cannot reach this one (#205). An agent
  that needs a running backend gets a database of its own, named in its brief.
  Changing the *schema* is fine when the issue says so; using that one database is not.
- **The shared backend gate image.** `make back-image` builds one tag every worktree runs
  its backend gates in. A branch that adds a tool to `backend/requirements.txt` rebuilds
  it, and every other branch loses that tool: on 2026-09-27 import-linter, pytest-randomly
  and mypy each vanished from siblings' gates as three branches took turns. An agent that
  needs a rebuilt image builds its own by name (`BACKEND_IMAGE=goalgetter-backend-<issue>
  make back-image`, then every gate with that `BACKEND_IMAGE`) and removes it by name
  when done. The batch rebuilds the shared tag once, from `main`, after the last merge
  that changed requirements.

## Make the agent measure

The largest difference between a good result and a plausible one. Wrong conclusions come
from reasoning about code that was not read, or a symptom explained without evidence.
Right ones come with a number, a reproduction, or an observed state attached.

**So brief for evidence.** Tell an agent what to measure and with what — a widget test
that reproduces the bug, a call through Swagger, a service invoked directly with Gemini
mocked. "It works now" from an agent that could not observe anything is worth nothing.

## Never filter a gate's output

`make check 2>&1 | grep passed` will show a linter saying it passed while pytest fails
underneath, and `make check | tail; echo $?` reports **`tail`'s** exit status, not
make's. Both have happened in this repo. The same goes for a merge: a truncated view of
`git merge` can hide conflicts that then get committed with their markers in.

**Read the end of the output, and read the real exit status** — run the gate on its own
line, or `set -o pipefail`.

**A log goes to the session's scratchpad, never beside the repo.** Saving a gate's output
with `> ../f173.log` from a worktree dumps it in `~/Desktop/Repos`, where nothing cleans
it: 43 such files had piled up there by 2026-09-27. Name the scratchpad path in the brief.

## When green is not the same green

- **A local gate reads the real `.env`; CI has placeholders.** A test that leans on a real
  value passes here and fails there. On 2026-09-27 it happened twice: an 11-byte
  `SECRET_KEY` in CI tripped PyJWT's key-length warning once warnings became errors
  (#206), and an empty `GOOGLE_CLIENT_ID` left a signed test token with no audience
  (#258). A branch is ready when CI is green, not when the local gate is.
- **A `live` check that passed may have run nothing.** Without the repository's API-key
  secrets the live workflow skips itself and concludes `success` (#265). Read its log
  before calling a Gemini change proven against the real API.
- **Merge on the sum means rebase and gate again** whenever `main` moved after a branch
  went green, even if GitHub still says `MERGEABLE`. A PR rebased before a sibling landed
  was never tested with that sibling: its new tests never ran under the sibling's
  stricter config, or its schema never met the sibling's snapshot check.

## Briefing a subagent

**Never the Fable model** (the user, 2026-09-27): no `model: "fable"` on an agent, in a
workflow, or anywhere else. Leave the model unset so the agent inherits it.

Give it, in this order:

1. **Its own worktree**, created for it, with the exact command. Never two branches
   taking turns in one checkout. Then `make setup` in it. (The test database needs
   nothing: every gate run starts its own.)
2. **`CLAUDE.md` first**, then the issue, then the specific files it will touch.
3. **What has landed recently** that it must build on, by name — `main` moves under
   long-running agents.
4. **The siblings and their files.**
5. **The never-touch list above.** Plainly: no compose, no deploy, no real Gemini or
   YouTube calls, no backend brought up against the shared database.
6. **What to measure**, and what it may use to measure it. If the issue names a cause,
   hand it over as the **first thing to check, not the thing to implement**.
7. **What is out of scope**, stated once.

Tell it to open a pull request and **not merge** — merging is the batch's job, because
only the batch knows what else is in flight. The batch then merges in priority order,
applying the PR rules in `CLAUDE.md`: everything that finished and is green merges,
database queries, schema changes and refactors included. A draft is unfinished work,
or work that hit a decision nobody had made and which changes what the user finally
receives — name that decision in the PR and move on to the next issue.

**Merge on the sum, not on the branch.** A batch's PRs each passed alone; what ships
is their merge. Merge them locally first, run the gate on the result, and only then
merge for real — that is where the line-limit ceiling fires and where two branches
that edited the same list collide.

## Reporting back

The user reads the morning report, not the transcript. For each issue: the PR, whether it
merged or waits and on what, the gates with their real numbers, and every decision taken
alone.

**Say what surprised you.** A hypothesis dying to a measurement is the process working,
and it is the part worth writing down — next time it is knowledge instead of a guess.

Two things are reported first, regardless: **a change to anything outside the repo**,
and **a decision reversed** — where the issue said one thing and the branch did another.
