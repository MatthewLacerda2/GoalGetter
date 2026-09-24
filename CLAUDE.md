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
It also gives the worktree its **own test database** (`make test-db`): the fixtures drop
every table, so two worktrees sharing one would wipe each other mid-run.

Run `make backend` or `make frontend` for the side you touched, or `make check`
for both, and see it pass **before pushing**.

`make backend` is four gates, cheapest first:

- **`make back-lint`** — the house rules below (`backend/tests/backend_linter.py`),
  then `ruff check` and `ruff format --check`. The rule set, and the reason for
  each choice in it, is `backend/pyproject.toml`. **`make back-fix`** applies
  exactly what this gate checks, so start there rather than editing by hand.
- **`make back-deadcode`** — `vulture`: a function, class or method no other
  module reaches. The whitelist for what only FastAPI, SQLAlchemy or `mock`
  calls lives in `backend/tools/deadcode.py`, four names long, each naming its
  caller. Growing it is how this gate stops working — delete the code instead,
  and if it really is a framework entry point, say which framework.
- **`make back-build`** — imports the app and generates the OpenAPI. It needs no
  database: it pins placeholder settings before the import and runs with no
  network at all, so a broken import or an unresolvable response model surfaces
  in a second.
- **`make back-test`** — pytest, the only one that needs the test database.

Ruff and vulture are in `backend/requirements.txt`, so they live in the backend
image the way pytest does: that image is where every Python tool runs locally,
since there is no venv here. CI has no image and overrides the interpreter
(`make back-lint PY=python`).

- **A red gate is never handed off as "probably pre-existing."** Re-run that one
  target on `origin/main`; only if it is red there too, say so, with the output.
- **Never pipe `make` into a chain that decides a push.** `make check | tail && git
  push` pushes on a red gate — a pipeline exits with its *last* command's status.
  Run the gate on its own line and read it.
- Setup failures read as such: `back-test` failing on `DATABASE_URL` wants
  `make env`; a refused connection wants `docker compose up -d postgres_test`;
  missing Dart packages want `make setup`; `No module named ruff` (or vulture)
  means the backend image predates `backend/requirements.txt` — `make back-image`.

The pre-commit hook (`.githooks/pre-commit`) runs only the gates for the side
whose files are staged. It is not a substitute for `make check`.

## House rules

`make back-lint` (`backend/tests/backend_linter.py`) enforces these. Run it before
the backend tests; if it fails, you have things to fix.

- **350 code lines** per `.py` file. Comment-only lines and docstrings are free;
  blank lines count. A file that is **data, not logic** opts out with a
  `# lint: data-file` header: invented content, hardcoded tables, Gemini
  prompts. Data is read, not reasoned about, so its length says nothing about
  whether the file does too much. Anything carrying branching, queries or rules
  does not qualify, however long it is, and the marker is never a way to keep a
  file that outgrew the limit. Split a data file only where that makes it
  easier to read — it keeps the exemption either way. No prompt needs the
  marker today: every one of them is far under 350 lines.
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
- **Signed-in screens, headless**: `make preview` builds the integrated app and serves
  it with its own backend on `:8093` (loopback and the tailnet only). `make claude-token`
  signs Claude in as a fictitious student, then `make shot ROUTES="/home /goals"` writes a
  phone-sized PNG per route to `shots/` — read them. Flutter web draws to a canvas, so
  the PNG, not the DOM, is the evidence. `make claude` does what `make claude-token`
  does after giving that student a lived-in history (three goals, two weeks of lessons,
  a tutor chat, resources) written straight to the dev database, so every screen has
  data; `ARGS=--fresh` rebuilds it. The preview's backend drops its schema on every
  start: re-run `make claude` (or `make claude-token`) after a rebuild.
- **Gemini and YouTube behaviour**: the services are plain functions — call them
  directly to see what the model actually returns.

Unit and widget tests are still the validation for most changes. Ask the user to
look only when they asked to, or when what is left is a judgement about how
something looks or feels.

## Pull requests

**A PR is one of two things, and nothing else:**

- **Merged by Claude** — the normal case. The work finished, CI is green, so it
  merges: database queries, refactors, CI changes, schema changes included. That
  the user will read it later is not a reason to hold it. The code is young and
  simple, the gates are what say it is ready, and the pull request is where the
  reasoning waits for him.
- **Draft** — two cases, and nothing else:
  - **the work did not finish**: an environment failure, red gates, a resource you
    do not have. Push what you have and comment the bottleneck. A draft is how
    unfinished work gets off one machine; it is never where a finished change waits.
  - **you hit a decision with no clear instruction, and how you decide changes what
    the user finally receives.** Then the PR stays a draft until he takes that
    decision *and* says how that kind of doubt is to be settled from then on — the
    answer is written into `CLAUDE.md`, the issue, or a skill, so the next session
    does not ask again. A decision that only changes how the code looks is yours.

**The database.** Creating and dropping tables and columns is allowed — there is no
production, and the schema is rebuilt on every backend start. Two conditions: the
change was **agreed with the user in conversation before the issue was written**, so
it is already decided when the work starts; and it is a **consequence of what the
issue defines**, never something invented while writing the code. A schema change
that surprises the user is the failure, not the schema change.

**Deployment.** Once the app is online (the Cloudflare tunnel, Google OAuth, the
first migration), it stays online. Every update to `main` rebuilds the containers and
brings them up with the new code. There is no staging: CI is the gate.

**A decision the plan did not cover** is yours to take when the information is at
hand and something points the way — a rule, a convention the codebase already
follows, or a run of past decisions in the same direction. Take it and record it in
the PR with its reason. With none of those behind it, the decision goes back to the
user and the PR is a draft that names it.

**Wait for CI to exist before reading it.** GitHub takes a few seconds to create a
run after a push, and in that gap `gh pr checks` answers "no checks reported" —
the same words it uses for a PR with genuinely no CI (workflows are path-filtered,
and drafts are skipped). A run can take **more than two minutes** to appear, and a
new workflow file may not fire on the push that adds it — so silence proves nothing.
Poll `gh run list --commit <sha>` until the run appears; if it never does, close and
reopen the PR (the workflows listen for `reopened`). Path filters compare the whole
PR against its base, not the last commit, so a docs-only push to a PR that touches
code still runs CI. On a draft the runs come back `skipped`, which is not a pass.

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
- **Every screen runs on the real API** (2026-09-21, #51–#57). The only mocks left
  are `app/dev/dev_fixtures.dart`, which the dev menu uses — and which routes taking
  a go_router `extra` still fall back to in production builds when the `extra` is
  missing (a web refresh), so those screens can show fixture data there.
- **Dev sign-in without Google.** A backend started with `DEV_LOGIN=true` serves
  `POST /auth/dev-login`; `make claude-token` (honours `BACKEND_PORT`) writes a
  bearer for "Fictitious Claude" to `.claude/token`, and a Flutter build with
  `--dart-define=DEV_LOGIN=true` offers the same sign-in on the start screen.
- **Analyzer backlog: 27 warnings, 533 infos** (2026-09-21, after integration), so CI runs `flutter
  analyze` with `--no-fatal-warnings --no-fatal-infos`. Next step: clear the
  warnings (mostly mechanical) and let them block.
- **The tailnet preview is plain HTTP on :8093.** `tailscale serve` (HTTPS on the
  tailnet name) is not enabled on this tailnet yet; the user enables it once from the
  admin link `tailscale serve --bg --https=443 http://127.0.0.1:8093` prints. Google
  sign-in will need that HTTPS origin.
- **Gemini model names drift.** They are defined once in `backend/utils/envs.py` and
  need a bump roughly monthly.

All rules can be overridden by the user if he explicitly said so in the current or
previous prompt, but not older than that.
