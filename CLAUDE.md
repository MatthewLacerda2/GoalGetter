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

## How the app decides

Four rules the user settled on 2026-09-24. They are why the code looks the way it does,
and an issue that needs one of them broken is the wrong shape.

- **Gemini writes content; arithmetic decides what appears.** Writing a question, a tutor
  reply or a resource's description is his. Choosing which questions a student gets, measuring
  how he is doing, and deciding whether it is worth generating more are deterministic
  formulas — testable without a network and free to run. The selection runs several times
  a day per student: as a model call it would be the app's largest cost and its least
  predictable behaviour. **And he is the tool of last resort** (2026-09-26): where a tool
  exists for the job, the tool does it. Google Search finds pages and the YouTube Data API
  finds videos; Gemini never supplies a link from memory, because he invents them (#175).
- **Content sits at the threshold of what the student knows** — always challenged, never
  handed more than he can take, because both extremes stop him progressing. That is a
  number: the chance he answers correctly, aimed at about 0.75. Classical Item Response
  Theory would aim at 0.5, which measures the student best; we are not optimising
  measurement, we are optimising that he comes back tomorrow.
- **The product goal is that he learns; the metric is that he returns every day.** A
  lesson is about two minutes — eight questions — because that is what keeps coming back
  cheap. More answers is also more evidence about him, so short and daily beats long and
  occasional twice over.
- **The goal is where he started, not where he is going.** When a student has learned
  everything a goal holds, the app moves him outward — to what that knowledge is useful
  for and what he seems interested in — rather than stopping. The target lives in its own
  append-only history — the `frontiers` table (#133), newest row wins — and the goal's own
  description stays as what he asked for on day one.

The rating is the student's ability in the Rasch sense, and a question's difficulty is
derived from his own answers — never tagged by Gemini, and never a column. Nothing is ever
reused between students: not questions, not resources, not contexts.

## Stack

- **Backend**: FastAPI, SQLAlchemy (async), Alembic, the Gemini SDK. Postgres with
  pgvector for embeddings.
- **Frontend**: Flutter, Riverpod for state. Targets mobile; distributed through
  the web first.
- **Gemini calls** live under `backend/services/gemini/<use-case>/`, each a folder
  with a `schema.py` (the Pydantic JSON shape Gemini must return), a prompt, and
  the function that calls the client. Callers get a typed result like any function.
  Every prompt is **written in English** and **names the language of its output** — the
  student's — outright; that line is written by hand in each prompt, there is no shortcut.
  And every prompt asks for the **shortest output that does the job**: tokens are the bill,
  and a response the code only parses needs no prose around it.

## Quality gates — `make check`

The root `Makefile` is the local runner, and GitHub Actions calls the same
targets; `make help` lists them. `make setup` once per checkout or worktree
installs the git hooks, seeds `.env`, and fetches the Flutter deps (which also
generates the l10n files — a fresh checkout shows ~69 analyzer errors until it
runs).
It also gives the worktree its **own test database** (`make test-db`): the fixtures drop
every table, so two worktrees sharing one would wipe each other mid-run.

The Flutter version is pinned in `frontend/pubspec.yaml` (`environment.flutter`), and CI
installs exactly that number rather than whatever `stable` resolves to — one analyzer, so
green here is green there (#121). `make frontend` checks it first (`front-version`) and
fails when this machine's SDK differs, naming both numbers and the one-line fix: pub reads
that pin as a floor, so only a machine *behind* it fails on its own, and this is what
catches one ahead of it (#147). Upgrading is that one line plus an analyzer run, and the
SDK at `~/development/flutter` moves with it.

Run `make backend` or `make frontend` for the side you touched, or `make check`
for both, and see it pass **before pushing**.

`make backend` is five gates, cheapest first:

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
- **`make back-migrations`** — `alembic upgrade head` on an empty schema, then
  `alembic check` against the models. The migrations are what builds the database;
  the tests build their tables from the models, so a model changed without a
  migration is green everywhere else and broken on deploy. It resets this
  worktree's test database, which is disposable by definition. When it goes red,
  `make back-revision M="what changed"` drafts the revision it is asking for —
  then read it, because autogenerate misses a pgvector extension, a mutual
  foreign key and an enum it should drop.
- **`make back-test`** — pytest. Together with `back-migrations`, the two that
  need the test database.

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
  means the backend image predates `backend/requirements.txt` — `make back-image`; a
  frontend gate failing on the Flutter version means the SDK moved without the pin, so bump
  `environment.flutter` and let the same pull request re-analyze.

Two hooks make that mechanical, both scoped to the side that changed and both
installed by `make hooks`:

- `.githooks/pre-commit` runs the house lints on the staged files — fast, and not
  a substitute for the gates.
- `.githooks/pre-push` runs `make backend` and/or `make frontend` for the sides the
  push contains. **This is the gate that matters**: nothing leaves the machine on a
  red gate, so a pull request is never opened on work whose gates were never seen
  green. Skipping it is `git push --no-verify`, deliberately.

Both skip a side they cannot run (no Docker, no Flutter, no `flutter pub get` here)
with a printed reason rather than blocking: a gate that always fails is a gate
nobody runs.

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
- **400 lines** per hand-written `.dart` file, and **60 code lines** per
  function. `make front-lint` (`frontend/tool/frontend_linter.dart`) enforces
  those, that the theme is the only source of colour, type, radius and spacing,
  and that every string a student reads comes from the ARB files — a key read
  nowhere, a key missing from a locale, a sentence written in Dart and a file
  under `lib/` nobody imports all fail it.
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
2. Write the tests (edit fixtures if needed). **The default suite never calls a real
   API** — Gemini and YouTube are always mocked, and `fixtures/network.py` fails any
   test that reaches past this machine and the test database. **The `live` suite does,
   and runs only when asked** (#176): tests marked `@pytest.mark.live` under
   `backend/tests/live/`, skipped by `make check` and by every-push CI, run by
   `make test-live` and by the `live` workflow — on a pull request that touches the
   Gemini, YouTube or link-validation code or the `google-genai` pin, and on its Run
   workflow button. A live test asserts a contract, never words (the answer parses; N
   texts embed into N vectors; a recommended resource survives validation), makes one
   call per use case on the smallest input, and the run prints how many calls it made.
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
- **Signed-in screens, headless**: `make preview` builds the integrated app and serves it
  with its own backend, on its **own database**, at `:8093` (loopback and the tailnet only).
  Signing in needs no Google: a backend started with `DEV_LOGIN=true` serves
  `POST /auth/dev-login`, `make claude-token` (honours `BACKEND_PORT`) writes a bearer for
  "Fictitious Claude" to `.claude/token`, and a Flutter build with
  `--dart-define=DEV_LOGIN=true` offers the same sign-in on the start screen. Then
  `make shot ROUTES="/home /goals"` writes a phone-sized PNG per route to `shots/` — read
  them. Flutter web draws to a canvas, so the PNG, not the DOM, is the evidence. A shot
  carries the student's active goal, so screens that need one photograph properly, and
  `GOAL=<id>` picks another (#127) — but a route that guards its go_router `extra`
  redirects away from a bare URL (#139), so those screens are reachable only through the
  dev menu. `make claude` does what `make claude-token` does after giving that student a
  lived-in history (three goals, two weeks of lessons, a tutor chat, resources) written to
  the preview's own database, so every screen has data; `ARGS=--fresh` rebuilds it. It
  survives a rebuild now (#157), so it is run once; the token still expires in 30
  minutes.
- **Gemini behaviour**: `make gemini` lists the use cases it can run; `make gemini
  ARGS='tutor-reply "Chess" "Learn chess" "What is a fork?"'` runs one for real and
  prints the raw text beside the parsed object, so a bad response format is visible
  instead of swallowed by the parser. It **spends real quota** — one run, one billed
  call — so never loop it, and never call it from a default-suite test.
- **YouTube behaviour**: the services are plain functions — call them directly to
  see what comes back.
- **Real calls are billed, so ask first.** Claude may call the real APIs to look at
  what they return — `make gemini`, `make test-live`, a throwaway script — but asks the
  user before each run (the user, 2026-09-26).

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

**The database.** A schema change is a migration in `backend/alembic/versions/`,
written and reviewed with the code that needs it — nothing rebuilds the schema on
start any more (#157), and data survives. Tables and columns can still be created
and dropped, on two conditions: the change was **agreed with the user in
conversation before the issue was written**, so it is already decided when the work
starts; and it is a **consequence of what the issue defines**, never something
invented while writing the code. A schema change that surprises the user is the
failure, not the schema change.

A clean local database is `make migrate ARGS='downgrade base'` then `make migrate`
— starting the backend no longer gives one away. A database whose tables predate
the migrations is `make migrate ARGS='stamp head'`, once.

**Deployment.** Once the app is online (the Cloudflare tunnel, Google OAuth, the
first migration), it stays online. Every update to `main` rebuilds the containers and
brings them up with the new code: the `migrate` service applies the migrations once
and the backend and `nightly` wait for it to exit 0, so a failed migration stops the
deploy instead of being served on top of. There is no staging: CI is the gate.

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

**When Claude finds a bug, stale documentation or a rule that should no longer apply,
Claude either fixes it within the task being done or files an issue for it — and then
tells the user** (2026-09-26). Never silently ignored, and never left only in a closing
message: a closing message is read once, an issue is still there next week.

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

- **Nothing backs the database up.** Since #157 the data survives a restart, which
  is the point — and makes losing it possible in a way it never was. No issue covers
  this yet.
- **Analyzer backlog: 0 warnings, 379 infos** (2026-09-25, measured on `main` after the
  batch). A warning now
  fails `make front-lint`; the infos are a separate, larger backlog and still
  only report (`--no-fatal-infos`). Next step: clear them and let them block too.
- **The deploy now runs a job that spends money.** `docker-compose.yml` carries a
  `nightly` service (#89, #96): one process that fills the null embeddings at **00:00**
  and runs the context → questions → resources chain for each qualifying student at
  **03:00**, America/Sao_Paulo. It waits for the hour before running, so a restart or a
  crash loop never spends quota, and it skips any student who did no lesson that day.
  Two changes on 2026-09-25 raised what a night costs: the chain can append a `frontiers`
  row, which pays for one extra embedding (#133); and the question step no longer tops up a
  thin bank but buys **eight questions per studying student per goal** on any night when
  tomorrow's lesson would be too easy (#135) — so a deep bank no longer saves anything, and
  a student who keeps missing his questions is now the cheap case rather than the expensive
  one. `make nightly ARGS='--once'` and `make embeddings` run them by hand.
- **The tailnet preview is plain HTTP on :8093.** `tailscale serve` (HTTPS on the
  tailnet name) is not enabled on this tailnet yet; the user enables it once from the
  admin link `tailscale serve --bg --https=443 http://127.0.0.1:8093` prints. Google
  sign-in will need that HTTPS origin.

All rules can be overridden by the user if he explicitly said so in the current or
previous prompt, but not older than that.
