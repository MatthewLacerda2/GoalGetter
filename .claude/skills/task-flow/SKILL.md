---
name: task-flow
description: The ordered procedure for a GoalGetter change, from request to merged PR — plan with no ambiguity left, worktree, TDD, make gates, check it running yourself, commit and push, open the PR in the right one of its three states, wait for CI properly, merge when the rules allow, clean up. Use whenever someone asks to build, fix, work on, start, continue or finish a change, and whenever you need to know what the next step is.
---

# Task Flow — GoalGetter

One change = one ordered pipeline. Phases run **in order**; when resuming, jump in at
the first one whose artifact is missing (see *Resuming*). The rules this applies live
in the root `CLAUDE.md` — this skill is the procedure, not a second copy of the rules.

There is no issue tracker yet: the request is whatever the user asked for, or a GitHub
issue if they point at one.

| # | Phase | Artifact |
|---|---|---|
| 0 | Orient | you know the change, the side(s), and the prior art |
| 1 | Plan, no ambiguity | a plan outside the checkout; every open decision answered |
| 2 | Worktree | branch + worktree, set up |
| 3 | Implement | tests first, then code |
| 4 | Gates + self-check | green `make` targets; the change seen running |
| 5 | Commit + push | commits on the remote |
| 6 | PR | a PR in its correct state, CI green |
| 7 | Merge | merged — by you, or on the user's word |
| 8 | Cleanup | worktree and branch gone |

## Phase 0 — Orient

1. **Decide the side**: `backend/` (FastAPI) or `frontend/` (Flutter). A change that
   spans both is still one branch and one PR — say which gates each side needs.
2. **Check what already exists.** `git fetch origin --prune`, then
   `gh pr list --search "<keyword>" --state all --limit 10`. A branch or merged PR on
   the subject gets read before anything is planned.
3. **Read prior art, cheapest first**: the root `CLAUDE.md` →
   `frontend/docs/backend_contract.md` (the endpoint spec and `## Decisions`) → the
   files the change actually touches.
4. **The request may not be the complaint.** When a request carries a theory ("the
   lesson screen is slow"), confirm the symptom before planning against the theory.

## Phase 1 — Plan, with no ambiguity left

1. Write **one** plan: *what* and *how*. It does **not** go in the checkout — a plan is
   working memory, not repository content.
2. List everything still open: a decision that could go two ways (a new screen or a
   sheet? which model? what happens when Gemini refuses?), data or credentials not at
   hand, a criterion that is not observable. **Ask the user all of it in one message.**
   A plan with a question open is not ready.
3. **Flag schema changes now.** Until the first migration exists, the DB drops itself
   on start; after it, a model change needs a migration, and the PR is ready-for-review
   (Phase 6).
4. End the plan with **how the change will be checked** — the concrete thing you will
   run, hit or look at in Phase 4. If you cannot write it, the plan is not finished.

Then ask "start it now?" — unless the request already said to build it.

## Phase 2 — Worktree

```bash
git -C <main-checkout> pull --ff-only
git worktree add ../GoalGetter-<slug> -b feat/<slug> origin/main
cd ../GoalGetter-<slug>
make setup          # hooks + .env + Flutter deps (and generated l10n)
```

Every worktree shares the one dev database for now. That is harmless while the backend
drops its schema on start; per-worktree databases arrive with the first migration.

Prefix `feat/`, `fix/`, `chore/` or `docs/`; the slug is English, lowercase, hyphenated.

## Phase 3 — Implement

- **Backend endpoints are TDD**: schemas → tests → endpoint (root `CLAUDE.md`). Gemini
  and YouTube are always mocked in tests.
- A new Gemini use case gets its own folder under `backend/services/gemini/` with
  `schema.py`, a prompt, and the calling function.
- DB access only through `backend/repositories/`.
- **Every failure a user can cause gets visible feedback where it happened**, through
  l10n keys. A bare `catch`, an error only logged, or a load with no error state is a
  bug — and so is a failed load rendered as an empty state.
- **Preserve line endings** on files you edit (the repo mixes CRLF and LF).
- **A decision that only shows up while building** is yours when something points the
  way — a rule, an existing convention, a run of past decisions. Take it and record it
  in the PR. Otherwise it goes to the user, and the PR is a draft.
- **A defect you discover** gets reported in the closing message, not fixed silently out
  of scope.

## Phase 4 — Gates, then see it running

`make backend` / `make frontend` for the side touched, `make check` for both. Record the
real numbers — the PR's gates line must be backed by output you read.

- **Never** `make check | tail && git push`: a pipeline exits with its last command's
  status, so that pushes on red.
- A red gate you believe is pre-existing: prove it on `origin/main` first, and say so.
- **Then look at it yourself.** Screens: the dev server on 8090 with `DEV_MENU=true`.
  Endpoints: Swagger on 8001. Gemini: call the service directly. Tear servers down when
  done. Ask the user to look only when they asked to, or when what remains is a
  judgement of look and feel.

## Phase 5 — Commit and push

Check `git status` first — never commit `.env`, keys, build output, or scratch files.
Conventional messages; end with the attribution lines the session provides. **Never push
to `main`.**

## Phase 6 — The PR

Pick the state from the root `CLAUDE.md` (*Pull requests*):

- **Draft** — stuck: red gate, missing resource, environment failure, a decision you may
  not take. Comment the bottleneck.
- **Ready for review** — changes a database query (`backend/repositories/`), carries a
  migration, is a refactor (>1100 lines added), or changes CI.
- **Otherwise** — you merge it yourself in Phase 7 once CI is green.

```bash
gh pr create --base main --head <branch> --title "<title>" --body-file <(cat <<'BODY'
…
BODY
)
```

**Wait for the CI run to exist before reading it** — `gh pr checks` says "no checks
reported" for a run not yet created, the same words as for no CI at all:

```bash
SHA=$(git rev-parse HEAD); n=0
until [ -n "$(gh run list --commit $SHA --limit 1 --json databaseId -q '.[].databaseId')" ] \
  || [ $n -ge 24 ]; do n=$((n+1)); sleep 5; done
gh pr checks <number> --watch
```

Nothing after two minutes means the PR genuinely has no checks — say so rather than
implying CI passed. A new workflow file may not fire on the push that adds it; push
again. On a draft, runs come back `skipped` — never quote that as a pass. Red CI is
fixed on the same branch, never left sitting.

## Phase 7 — Merge

Merge yourself when CI is green, unless the PR is a ready-for-review kind or the user
said to leave it — then say which rule holds it. When the user gives the word, carry it
through: wait for CI, merge, stop and report if it fails.

Close with a short report: the PR URL and whether it merged or waits (and why); the gates
with their real numbers; what you checked running and what you did not; every decision
taken alone; defects found and not fixed.

## Phase 8 — Cleanup

After a merge, run `cleanup-local`. Not merged → no cleanup; the worktree is still
needed.

## Resuming

| Is there… | No → | Yes → |
|---|---|---|
| a plan with no open question? | Phase 1 | ↓ |
| a worktree for it? | Phase 2 | ↓ |
| uncommitted or unpushed work? | Phases 3–5 | ↓ |
| a PR? | Phase 6 | ↓ |
| is it a draft? | ↓ | what is it stuck on? clear it, undraft |
| green CI? | Phase 6 — fix it | ↓ |
| merged? | Phase 7 | Phase 8 |

Check state explicitly: `gh pr view <branch> --json number,isDraft,state,mergedAt,url`.
