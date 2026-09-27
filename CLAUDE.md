All documentation (comments, markdown) and code are written in **English**, even
when the user writes in Portuguese. User-facing strings in the app go through the
l10n ARB files, never a hardcoded literal.

The system is developed and deployed on Linux. This is a **homedeploy**: served
through a Cloudflare Tunnel from this machine. Google Cloud provides OAuth and the
Gemini API (project `goalgetter-ai-tutor-1996`).

## What GoalGetter is

An AI tutor: a student names what he wants to learn and the app teaches it, a little
every day. The point is that he leaves every day having learned something; the metric is
that he comes back tomorrow.

The rules that shape almost every change, in one line each:

- **Gemini writes content; arithmetic decides what appears** — selection, measurement,
  whether to generate, where the right option sits. And Gemini is the tool of last resort:
  where a tool exists (Google Search, the YouTube API), the tool does it.
- **His answers are the measurement**; what he says about himself is his opinion, and
  what he says he wants to reach is not a ceiling.
- **Exercises teach, they do not test**: the simplest possible, one step past what he has
  shown he knows. 20 words at most. Nothing is reused between students.
- **Every prompt is in English, names his language, and asks for the shortest output.**

**[`SOUL.md`](SOUL.md) is the project's philosophy** — the business rules and the reasoning
behind them. It is optional reading: open it when a decision is subjective, when a
business rule is unclear, or before changing anything a student sees. The endpoint spec
is `frontend/docs/backend_contract.md`; read it before changing onboarding, lessons, or
the background jobs.

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
  Which language it names is `services/gemini/output_language.py`'s answer: his
  `students.language`, else what he typed, else English (#173).
  And every prompt asks for the **shortest output that does the job**: tokens are the bill,
  and a response the code only parses needs no prose around it.

## Quality gates — `make check`

The root `Makefile` is the local runner, and GitHub Actions calls the same
targets; `make help` lists them. `make setup` once per checkout or worktree
installs the git hooks, seeds `.env`, and fetches the Flutter deps (which also
generates the l10n files — a fresh checkout shows ~69 analyzer errors until it
runs).
There is no test database to set up: each run of `make back-test` or `make
back-migrations` starts its **own disposable Postgres** (`tools/test-db.sh`, #205) —
empty, on a tmpfs, removed by name when the run ends however it ends — so any number of
worktrees run the gates at once and nothing is left behind.

The Flutter version is pinned in `frontend/pubspec.yaml` (`environment.flutter`), and CI
installs exactly that number rather than whatever `stable` resolves to — one analyzer, so
green here is green there (#121). `make frontend` checks it first (`front-version`) and
fails when this machine's SDK differs, naming both numbers and the one-line fix: pub reads
that pin as a floor, so only a machine *behind* it fails on its own, and this is what
catches one ahead of it (#147). Upgrading is that one line plus an analyzer run, and the
SDK at `~/development/flutter` moves with it.

Run `make backend` or `make frontend` for the side you touched, or `make check`
for both, and see it pass **before pushing**. The frontend gates install exactly
`pubspec.lock` first (`front-deps`), so a lock that moved since the last `pub get` is
not a false red (#227); `make front-test FILE=test/...` runs one test file.

**The Riverpod providers are generated, and the `*.g.dart` files are committed** (#225).
After changing an `@riverpod` function or class, run **`make front-codegen`** (build_runner:
~30 s warm, ~2 min cold) and commit what it rewrites; it fails when anything was stale, and
CI runs it on every frontend pull request (the pre-push hook, when the push touches a file
that parts a `.g.dart`).

`make backend` is six gates, cheapest first:

- **`make back-lint`** — the house rules below (`backend/tests/backend_linter.py`),
  the layer contracts (import-linter), then `ruff check` and `ruff format --check`. The
  rule set, the contracts, and the reason for each choice in them, is
  `backend/pyproject.toml`. **`make back-fix`** applies what ruff checks, so start
  there rather than editing by hand.
- **`make back-deadcode`** — `vulture`: a function, class or method no other
  module reaches. The whitelist for what only FastAPI, SQLAlchemy, `enum` or `mock`
  calls lives in `backend/tools/deadcode.py`, five names long, each naming its
  caller. Growing it is how this gate stops working — delete the code instead,
  and if it really is a framework entry point, say which framework.
- **`make back-build`** — imports the app and generates the OpenAPI. It needs no
  database: it pins placeholder settings before the import and runs with no
  network at all, so a broken import or an unresolvable response model surfaces
  in a second. It writes that OpenAPI to **`backend/openapi.json`**, which is
  committed, and fails when the write changed it: the API moved, so read the diff
  and commit it (#213). That is how every API change shows in a pull request.
- **`make back-types`** — mypy, `strict`, over all of `backend/` (#209): every
  function annotated, no explicit `Any` in our own code, no bare `dict` or `list`.
  Data that crosses a layer is a Pydantic model, a dataclass or a `TypedDict`, never
  `dict[str, ...]` standing in for one. Tests are held to a looser standard (their
  bodies are checked, their signatures need not be). The configuration and the
  reason for each exception is `[tool.mypy]` in `backend/pyproject.toml`. The first
  run in a worktree takes ~40 s filling `.mypy_cache`; after that, seconds. A call
  through `run_gemini`/`run_gemini_background` passes a use case's arguments **by
  name**: the checker catches an argument of the wrong type, not two strings swapped.
- **`make back-migrations`** — `alembic upgrade head` on an empty database, then
  `alembic check` against the models. The migrations are what builds the database —
  the test suite's too — but only this gate compares the result with the models, so a
  model changed without a migration is caught here and nowhere else. When it goes red,
  `make back-revision M="what changed"` drafts the revision it is asking for —
  then read it, because autogenerate misses a pgvector extension, a mutual
  foreign key and an enum it should drop.
- **`make back-test`** — pytest, on a database started for the run: the session
  fixture checks it is empty, migrates it to head, and each test rolls back. The suite
  runs in a container that shares that database's network namespace and nothing else,
  so from inside it the live database on 5434 does not exist; and in-process
  `DATABASE_URL` is a host that cannot resolve, so a job that opens
  `AsyncSessionLocal` without the test's session fails loudly (`fixtures/network.py`).
  CI runs the same targets with `PY_TESTDB=python TEST_DB_MODE=published`.
  Its config is `[tool.pytest]` in `backend/pyproject.toml` (#206): an unknown marker,
  a warning, a real `sleep` or a live test outside `tests/live/` fails the run, the
  order is shuffled (pytest-randomly; the seed is the run's last line), and the whole
  suite is held to a coverage floor. `FILE=`, `K=` and `ARGS=` run part of it, unmeasured;
  `make back-pure` runs the tests not marked `db` with no database, in seconds.

Ruff, vulture and mypy are in `backend/requirements.txt`, so they live in the backend
image the way pytest does: that image is where every Python tool runs locally,
since there is no venv here. CI has no image and overrides the interpreter
(`make back-lint PY=python`).

- **A red gate is never handed off as "probably pre-existing."** Re-run that one
  target on `origin/main`; only if it is red there too, say so, with the output.
- **Never pipe `make` into a chain that decides a push.** `make check | tail && git
  push` pushes on a red gate — a pipeline exits with its *last* command's status.
  Run the gate on its own line and read it.
- Setup failures read as such: `back-migrations` failing on `GEMINI_API_KEY` wants
  `make env` (`back-test` reads no `.env`: the suite pins every setting it uses,
  `backend/tests/fixtures/environment.py`, #207); a test database that never comes up prints its own log (the image is
  `pgvector/pgvector:pg18`, the stack's own);
  missing Dart packages want `make setup`; `No module named ruff` (or vulture, mypy, hypothesis)
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

`make check` runs a third gate, **`make ops-lint`** (#230): shellcheck on every tracked
`*.sh` and hook, hadolint on every Dockerfile, both from images the Makefile pins by
digest, every finding fatal; hadolint's exceptions and their reasons are `.hadolint.yaml`.
The pre-push hook runs it when a push touches one of those files. In CI, `ops-lint.yml`
runs it and `images.yml` builds every compose image on a pull request that changes what
goes into one — a Dockerfile that would break the deploy breaks the pull request first.

## House rules

`make back-lint` (`backend/tests/backend_linter.py`, and import-linter for the
layer contracts) enforces these. Run it before
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
- **400 lines** per hand-written `.dart` file, **60 code lines** per function and
  **50 per test**. `make front-lint` (`frontend/tool/frontend_linter.dart`) enforces
  those, that the theme is the only source of colour (an alpha included), type,
  radius, spacing and size — a `SizedBox(height: 24)` fails like an `EdgeInsets.all(16)` —
  and that every string a student reads comes from the ARB files, in any named argument
  of a constructor. A key read nowhere, a key missing from a locale, a file `lib/main.dart`
  does not reach and a public member nothing in `lib/` names all fail it: **a test's use
  does not count**, so a test never keeps dead code alive (#227).
- **A Flutter feature is `data/` → controller → screen** (#222). `data/<feature>_api.dart`
  talks HTTP; a code-generated controller under `presentation/controllers/` holds the
  screen's state and calls the API; the screen only watches it. A feature's
  `presentation/` holds `controllers/`, `screens/` and `widgets/` and nothing else, and
  no screen or widget imports `data/`. `make front-lint` enforces both;
  `frontend/tool/layer_rules.dart` says which folder holds what. A route's `extra`
  carries domain objects, never an icon, a colour or a translated string.
- **Database access only through `backend/repositories/`.** Anywhere else, the only
  things imported from SQLAlchemy (or a driver) are `AsyncSession`, to annotate, and
  `sqlalchemy.exc`, to catch; and nothing calls a statement method (`execute`,
  `add_all`, `scalars`...) on anything, or `add` / `delete` / `get` on a session,
  whatever it is named (#211). Tests and fixtures are exempt.
- **The layer boundaries are import contracts** (#211), in `backend/pyproject.toml` under
  `[tool.importlinter]`, each with its reason, and `make back-lint` checks them
  (import-linter follows indirect imports too): `core/` imports no other layer;
  `models/` and `repositories/` never import `services/` or `api/`; the arithmetic
  (`services/lessons/`, `services/jobs/nightly_decision.py`) never reaches
  `services/gemini/`; the Gemini layer never imports `models/` or `repositories/` — it
  returns content and the caller builds the rows; and only `services/gemini/client/`
  imports `google.genai`. A broken contract is fixed by moving the code, never by an
  exemption. Whether an endpoint may call a repository directly is **not decided** and
  has no contract.

When a file or endpoint outgrows its limit, one of two things is true. Either the
vision is unclear — then clap back at the user: ask, or point out what is wrong or
not well defined. Or the feature has genuinely grown — then split it by
responsibility. A test that needs to be complex means the feature is designed
wrong; tests must never be complex.

## Endpoints — TDD

1. Define what the endpoint does, then the request and response schemas.
2. Write the tests (edit fixtures if needed). **The default suite never calls a real
   API** — Gemini and YouTube are always mocked, and `fixtures/network.py` fails any
   test that reaches anything but the test database — loopback, DNS, UDP and child
   processes included. **The `live` suite does,
   and runs only when asked** (#176): tests marked `@pytest.mark.live` under
   `backend/tests/live/`, skipped by `make check` and by every-push CI, run by
   `make test-live` and by the `live` workflow — on a pull request that touches the
   Gemini, YouTube or link-validation code or the `google-genai` pin, and on its Run
   workflow button. A live test asserts a contract, never words (the answer parses; N
   texts embed into N vectors; a recommended resource survives validation), makes one
   call per use case on the smallest input, and the run prints how many calls it made — a
   test that bills more than its `live(calls=N)` marker allows (default 1) fails.
3. Implement the endpoint until the tests pass. An endpoint that fails its tests is
   not ready.

We focus on unit tests. Always run the backend tests before committing backend
changes.

The Flutter side is then updated **by hand** to match. We do not generate a client
SDK: generated code duplicated the frontend's domain models and went stale the moment
the API changed. The source of truth is the committed snapshot, `backend/openapi.json`
(`make back-build` keeps it current). The calls live in `frontend/lib/features/*/data/`,
one API class per feature, reusing the feature's domain models; `core/api/` holds only
the client and `ApiRoute`, the enum of every method and path the app calls — the
client takes nothing else. The contract test (`frontend/test/contract/`) reads the
snapshot and fails `make frontend` when an `ApiRoute` is not served, or when a fixture
a fake backend answers with is not what the backend could send: every fake answers
through `contractClient`, which checks each reply against its response schema
(missing, invented or mistyped fields, an undeclared success status). A new call is a
new `ApiRoute`; a fixture that is wrong on purpose is named in the fake's `malformed`.
A string enum mirrored on both sides is checked there too (`schemaEnum`).

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
  ones that need route arguments. Those run on fixtures; the rest call the backend,
  and without a session the router sends them to the start screen (#224).
- **Golden tests** (`frontend/test/goldens/`, #226) draw each screen of the real app, in
  light/English and dark/Portuguese, with Roboto from the pinned SDK and the app's own
  icon fonts (no network), and compare it pixel for pixel inside `make front-test`. A red
  one leaves the reference, the new image and their diff in `test/goldens/failures/` (on
  CI, the `golden-failures` artifact). A change that moves a screen on purpose runs
  **`make front-goldens`** and commits the PNGs it rewrote — read them first; the images
  in the pull request's diff are the review. References are drawn here, on Linux with the
  pinned Flutter, the same pair CI runs.
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
A user timer does it (#105): every two minutes `tools/deploy/deploy.sh` fetches main and,
when it moved, builds and then brings the stack up — build first, so a failed build leaves
the old containers serving. `make deploy` runs it now, `make deploy-log` shows what it did,
`make deploy-install` sets it up on a new machine. So **a merge is a deploy**: nothing is
merged that should not go live within minutes.

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
Poll `gh run list --commit <sha>` — the **full** 40-character sha; a short one silently
returns `[]` — until the run appears; if it never does, close and
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

- **Cloudflare's edge may still hold year-old copies of web files.** Until #197 nginx
  served every `*.js`/`*.png` as `public, immutable` for a year, and Flutter web's file
  names carry no hash. A **Purge Everything** in the Cloudflare dashboard clears what is
  already cached (no API token here to do it); from #197 on, files are revalidated.
- **Nothing backs the database up.** Since #157 the data survives a restart, which
  is the point — and makes losing it possible in a way it never was. No issue covers
  this yet.
- **Analyzer backlog: 0 warnings, 263 infos** (2026-09-27, `dart analyze` after #227;
  riverpod_lint contributes none). A warning now fails `make front-lint`, riverpod_lint's
  included since it runs `dart analyze` rather than `flutter analyze` (#169), and the lints
  whose finding is a bug (`unawaited_futures`, `use_build_context_synchronously`,
  `cast_nullable_to_non_nullable`, …) are warnings since #227 — the list and the reason
  for each is `frontend/analysis_options.yaml`. The infos left are style and still only
  report. Next step: clear them and let them block too (`--fatal-infos`).
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
  one. A new goal's first batch is the **18-exercise placement**, and nothing more is bought
  for a goal until it holds 18 answers (`PLACEMENT_SIZE`, 2026-09-26). Since #175 the resources step also spends **one YouTube `search.list` per goal-run
  (100 of the free 10,000 daily units)** and no longer embeds up front — the midnight
  backfill does. `make nightly ARGS='--once'` and `make embeddings` run them by hand.
- **The tailnet preview is plain HTTP on :8093.** `tailscale serve` (HTTPS on the
  tailnet name) is not enabled on this tailnet yet; the user enables it once from the
  admin link `tailscale serve --bg --https=443 http://127.0.0.1:8093` prints. Google
  sign-in will need that HTTPS origin.

All rules can be overridden by the user if he explicitly said so in the current or
previous prompt, but not older than that.
