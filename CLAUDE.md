All documentation (comments, markdown) and code are written in **English**, even
when the user writes in Portuguese. User-facing strings in the app go through the
l10n ARB files, never a hardcoded literal.

The system is developed and deployed on Linux. This is a **homedeploy**: served
through a Cloudflare Tunnel from this machine. Google Cloud provides OAuth and the
Gemini API (project `goalgetter-ai-tutor-1996`).

## What GoalGetter is

An AI tutor. A student names something they want to learn — a *goal* — and the app
teaches it through short lessons, a chat mentor, and curated resources, adapting to
the student over time. Generative AI is what makes it possible: the content is
generated and curated per student.

A goal names *what the student wants to learn about*, not a course with a finish
line. Progression is measured against the student, not against a syllabus. The
endpoint spec and the product decisions behind it live in
`frontend/docs/backend_contract.md`; read it before changing onboarding, lessons, or
the background jobs.

## Stack

- **Backend**: FastAPI, SQLAlchemy (async), Alembic, the Gemini SDK. Postgres with
  pgvector for embeddings.
- **Frontend**: Flutter, Riverpod for state. Targets mobile; distributed through
  the web first.
- **Gemini calls** live under `backend/services/gemini/<use-case>/`, each a folder
  with a `schema.py` (the Pydantic JSON shape Gemini must return), a prompt, and
  the function that calls the client. Callers get a typed result like any function.

## Quality gates — `make check`

The root `Makefile` is the local runner, and GitHub Actions calls the same
targets; `make help` lists them. `make setup` once per checkout or worktree
installs the git hooks, seeds `.env`, and fetches the Flutter deps (which also
generates the l10n files — a fresh checkout shows ~69 analyzer errors until it
runs).

Run `make backend` or `make frontend` for the side you touched, or `make check`
for both, and see it pass **before pushing**.

- **A red gate is never handed off as "probably pre-existing."** Re-run that one
  target on `origin/main`; only if it is red there too, say so, with the output.
- **Never pipe `make` into a chain that decides a push.** `make check | tail && git
  push` pushes on a red gate — a pipeline exits with its *last* command's status.
  Run the gate on its own line and read it.
- Setup failures read as such: `back-test` failing on `DATABASE_URL` wants
  `make env`; a refused connection wants `docker compose up -d postgres_test`;
  missing Dart packages want `make setup`.

The pre-commit hook (`.githooks/pre-commit`) runs only the gates for the side
whose files are staged. It is not a substitute for `make check`.

## House rules

`make back-lint` (`backend/tests/backend_linter.py`) enforces these. Run it before
the backend tests; if it fails, you have things to fix.

- **350 code lines** per `.py` file. Comment-only lines and docstrings are free;
  blank lines count. A file that is data rather than logic (Gemini prompts,
  hardcoded tables) opts out with a `# lint: data-file` header.
- **50 lines** per endpoint and per test function.
- **400 lines** per hand-written `.dart` file.
- **Database access only through `backend/repositories/`.** No `select` /
  `insert` / `update` / `delete` imports and no `db.execute` / `db.add` /
  `db.delete` anywhere else.

When a file or endpoint outgrows its limit, one of two things is true. Either the
vision is unclear — then clap back at the user: ask, or point out what is wrong or
not well defined. Or the feature has genuinely grown — then split it by
responsibility. A test that needs to be complex means the feature is designed
wrong; tests must never be complex.

## Endpoints — TDD

1. Define what the endpoint does, then the request and response schemas.
2. Write the tests (edit fixtures if needed). Tests use fixtures, never real APIs —
   Gemini and YouTube are always mocked.
3. Implement the endpoint until the tests pass. An endpoint that fails its tests is
   not ready.

We focus on unit tests. Always run the backend tests before committing backend
changes.

The Flutter side is then updated **by hand** to match. We do not generate a client
SDK: generated code duplicated the frontend's domain models and went stale the moment
the API changed. Do not regenerate or import `client_sdk/`. `/api/v1/openapi.json`
stays the source of truth — read it and write the API layer under
`frontend/lib/core/api/`, reusing the existing domain models.

## Worktrees, ports and dev servers

Never work on `main` locally: `git pull` there, then create a worktree off
`origin/main`. Prefix branches `feat/`, `fix/`, `chore/` or `docs/`. **Never push to
`main`** — always a branch and a PR.

**The default ports are not ours.** 8000 and 8080 on this machine belong to other
projects. Run the backend on **8001** and the Flutter dev server on **8090**:

```
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8090 --dart-define=DEV_MENU=true
```

`docker-compose.yml` uses fixed `container_name`s, so two stacks collide: take the
other one down first rather than working around it.

## Checking your own work

You do not need to be asked to bring a change up and look at it yourself. Green
gates prove the code runs; they do not prove it is the right change.

- **Screens**: `DEV_MENU=true` opens a dev index of every screen, including the
  ones that need route arguments, all running on mocks.
- **Endpoints**: Swagger is at `/api/v1/docs` (e.g. `http://localhost:8001/api/v1/docs`).
- **Gemini and YouTube behaviour**: the services are plain functions — call them
  directly to see what the model actually returns.

Unit and widget tests are still the validation for most changes. Ask the user to
look only when they asked to, or when what is left is a judgement about how
something looks or feels.

## Pull requests

**A PR is one of three things, and nothing else:**

- **Draft** — the work did not finish: an environment failure, red gates, a
  resource you do not have, or a decision you may not take (below). Push what you
  have and comment the bottleneck. A draft is how unfinished work gets off one
  machine; it is never where a finished change waits.
- **Ready for review** — the change **creates or changes a database query** (touches
  `backend/repositories/`), **carries a migration**, **is a refactor** (adds more
  than 1100 lines, removals not counted), or **changes CI**. It waits for the user's
  word; when it comes, carry it through: wait for CI, merge when green, stop and
  report if it fails.
- **Merged by Claude** — everything else, once CI is green, unless the user said
  beforehand to leave it. That the user will see the change is not a reason to
  hold it: the tests are the gate.

**A decision the plan did not cover** is yours to take when the information is at
hand and something points the way — a rule, a convention the codebase already
follows, or a run of past decisions in the same direction. Take it and record it in
the PR with its reason. With none of those behind it, the decision goes back to the
user and the PR is a draft that names it.

**Wait for CI to exist before reading it.** GitHub takes a few seconds to create a
run after a push, and in that gap `gh pr checks` answers "no checks reported" —
the same words it uses for a PR with genuinely no CI (workflows are path-filtered,
and drafts are skipped). A new workflow file may also not fire on the push that adds
it. Poll `gh run list --commit <sha>` until the run appears. On a draft the runs
come back `skipped`, which is not a pass.

A PR description opens with a short **preface** — why the PR exists and what was
done — then is shaped to the change (Context / Solution / Result is a sound default,
not a form). Describe the change, not the journey, and stay at the altitude of what
changed: screens by route, endpoints, tables, services.

Any defect found along the way gets **reported** in the closing message, not
silently fixed out of scope and not silently ignored.

A PR that closes an issue opens with `Closes #<number>` — check the number; a typo
closes the wrong issue, or none, silently.

## Issues

Work lives in **GitHub issues** — there is no other tracker. An issue is the agreed
purpose and direction of a piece of work, written before it: an intention, not a spec.
When the work diverges, the **pull request is the source of truth**.

- **Title** starts with a scope tag — `[FE]` (Flutter), `[BE]` (FastAPI), `[FS]` (both),
  `[OT]` (Docker, CI, root files, Terraform, docs) — then a sentence saying the outcome.
- **One type label**: `architecture`, `infrastructure`, `bug`, `documentation`,
  `foundation`, `feature`.
- **At most one stage label**, `planning` or `human`. Both mean **do not start**,
  absolutely; their absence means ready, including on an issue filed a minute ago. The
  judgement lives in the label, so put it on honestly.
- **`minor`** is a size marker (~30 lines or fewer), not a type.

**Priority — `architecture` → `infrastructure` → `bug` → `foundation` → `feature`;
`documentation` never waits its turn.** That is "foundations come first" as an order,
and it governs what gets **merged**, not what gets **worked**.

The same nine labels are used across the user's repos. **`issue-write` and
`issue-batch` hold the procedures** (`.claude/skills/`) — invoke them rather than
reconstructing one from memory, and name them when briefing a subagent. Where they
disagree with this file, this file wins. `cleanup-local` tidies merged worktrees and
branches afterwards.

## Documentation

Documentation is for AI agents navigating the code: record the decisions that are
not self-evident from it. Business logic is written by the user, or at their
request.

## Token optimization (RTK)

RTK is installed globally. Prepend `rtk` to commands with large output — `rtk git
diff`, `rtk git status`, `rtk run <command>` for verbose compiler output or logs.
It strips ANSI codes and truncates repetitive walls of text; trust the compressed
output.

---

The sections below are heads-up so we remember issues and build with future changes
in mind. You are free to change them so long as the user is aware; if he isn't,
remind him and ask.

===== KNOWN ISSUES =====

- **The database drops its whole schema on every backend start.** The lifespan in
  `backend/main.py` runs `DROP SCHEMA public CASCADE` then `create_all`. Deliberate
  while the models settle; no data survives a restart. There are **no migrations**
  yet — Alembic is scaffolded and `versions/` is empty. Plan: lock the schemas after
  frontend integration, generate the first migration, and switch startup to it.
- **Line endings are mixed** — roughly 20 files CRLF, the rest LF. Preserve a file's
  existing endings when editing: a tool that rewrites them turns a one-line change
  into a whole-file diff.
- **The frontend is fully mocked.** `AppStartController` is hardcoded to a
  returning user with an active goal, and every feature reads its `debug/mock_*.dart`.
  Integration replaces these one endpoint at a time.
- **Authed endpoints need a real Google token.** There is no test-token mint, so
  `POST /goals` and the auth routes can only be driven through the tests or a real
  sign-in.
- **Analyzer backlog: 60 warnings, 635 infos** (2026-09-21), so CI runs `flutter
  analyze` with `--no-fatal-warnings --no-fatal-infos`. Next step: clear the
  warnings (mostly mechanical) and let them block.
- **`SECRET_KEY` hardcoded in `backend/utils/envs.py` is dead code** — JWTs are
  signed with `settings.SECRET_KEY` from `.env`. Delete the constant.
- **Gemini model names drift.** They are defined once in `backend/utils/envs.py` and
  need a bump roughly monthly.

All rules can be overridden by the user if he explicitly said so in the current or
previous prompt, but not older than that.
