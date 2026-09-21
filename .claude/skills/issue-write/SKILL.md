---
name: issue-write
description: Write a GitHub issue for this repo — what it must contain, which labels it carries, and when Claude may file one unprompted. Use when filing an issue, splitting an idea into issues, or deciding whether something noticed mid-work deserves one.
---

# Writing an issue

The unit of work here is a well-specified GitHub issue. A future Claude reads it
**cold** and says *"I understand the assignment, I know how to proceed."* That is what
lets an issue run unattended, overnight, with nobody to ask (`issue-batch`).

It is still an *intention*, not a contract. The *Suggestion* may not survive contact
with the code, and when the work diverges the **pull request** is the source of truth.
Write the issue so someone can start without you — not so nobody may deviate.

## What it contains

- **Context** — the problem, and what we want once it is addressed. This is the half
  that survives: a reason written down can be re-judged when circumstances change; one
  that was never written can only be obeyed or ignored.
- **Suggestion** — the shape of the work, *not* the implementation intrinsics. Name the
  decisions the implementer must make and leave them theirs. Mark the ones already
  settled **`(decided)`**; it is the cheapest way to tell "I chose this" apart from
  "someone must choose".
- **Definition of done** — the observable result, and the boundary. Say what is
  explicitly **out of scope**; a boundary stated once saves an argument later. The last
  line is the gate it must leave green: `make backend`, `make frontend`, or `make check`.

**Evidence beats assertion.** Quote the file, the lint rule, the failing test, the line
that is actually wrong. *"`AppStartController.evaluate()` returns
`authenticatedReady` unconditionally"* means nobody has to re-derive it. "The app start
is broken" is worth less.

**A cause is a hypothesis; say which half is which.** Evidence is about the *problem* —
the file, the rule, the failing test — the half an issue can observe. The *diagnosis*,
why it is happening, is the part most likely to be wrong and most likely to be believed
anyway, because an issue reads with the authority of a decision. Name the cause — an
issue that suppresses its best guess wastes it — but name it *as* a guess: say what it
rests on, and tell the implementer to confirm it before building on it. *"I think X,
because Y; confirm it first"* costs one clause. A diagnosis written as fact is obeyed.

This repo already has the example. The lesson screen spun forever, and the plausible
theory was a slow mock. The real cause was an exception thrown by writing to a Riverpod
provider during `initState`, swallowed because the call was unawaited and the throwing
line sat outside its `try`. Found by reproducing it in a widget test, not by reading.

**Say what it looks like.** The app is a phone screen. When a change is visible, describe
what the student sees afterwards, and which screen it is on. When it is not visible at
all, say that too.

**Cite what it relates to.** Sibling issues, the pull request that exposed it, the rule
in `CLAUDE.md` it turns on, the endpoint in `frontend/docs/backend_contract.md`. A future
reader arrives with no memory of today.

**Title carries a scope tag** — `[FE]` (Flutter), `[BE]` (FastAPI), `[FS]` (both), `[OT]`
(Docker, CI, root files, Terraform, docs) — then a sentence that says the outcome.
`[BE] A returning student lands on their goal instead of a hardcoded one`, not
`[BE] GET /me`.

## The three gates

An idea becomes an issue only when all three hold. If any fails, **push back instead of
complying**:

1. **Understanding** — restate the *problem*, not the solution the user reached for. A
   solution is downstream of a problem, and an issue written from the solution inherits
   whatever was wrong upstream of it. If unsure, restate and confirm; do not guess.
2. **Value** — real value to the student or to how we build. No busywork, no features
   for their own sake. Pushing back on dead weight happens before the issue exists.
3. **Craft** — this stack's good practice and this repo's own standards. Most of them
   are lint rules.

### What "Craft" means in this repo

An issue that cannot be implemented without breaking one of these is the wrong shape —
say so and propose the right one.

- **The backend layers, one direction.** `api/` → `schemas/` → `services/` →
  `repositories/`. **The database is touched in `backend/repositories/` and nowhere
  else**; the house lint fails anything that imports `select`/`insert`/`update`/`delete`
  or calls `db.execute`/`db.add` outside it.
- **Endpoints are TDD**: schemas, then tests, then the endpoint. Gemini and YouTube are
  always mocked in tests — an issue whose tests need a real API call is the wrong shape.
- **A Gemini use case is a folder** under `backend/services/gemini/<use-case>/`: the
  Pydantic `schema.py` Gemini must return, the prompt, and the function that calls the
  client. A new use case that is not that shape needs a reason.
- **Pydantic is the contract, and Flutter mirrors it by hand.** There is no generated
  client; nothing checks that the two agree. Any issue that changes a request or
  response body is `[FS]` and owns both sides.
- **Every user-facing string goes through the l10n ARB files** — in all five locales.
  Code, comments and docs are English only.
- **Every failure a user can cause gets visible feedback** where it happened. A failed
  load rendered as an empty state is a bug.
- **Length discipline is enforced**: 350 code lines per `.py`, 50 per endpoint and per
  test, 400 per hand-written `.dart`. An issue whose honest shape is a 600-line module
  needs splitting by responsibility first. The ceiling fires on the *sum* of what
  merges — see `issue-batch`.
- **No drift.** Every gate is a `Makefile` target and CI calls the same targets. An
  issue that proposes a new check puts it in the `Makefile`; a check that lives only on
  one machine does not exist.
- **Prefer expression over description.** If the outcome is "everyone remembers to do
  X", the issue is wrong — ask for the lint rule, the type, or the config that makes X
  the only reachable option.
- **Foundations come first.** An issue that builds on a structure that does not exist
  yet is two issues.
- **Progression follows the student, not a syllabus.** A goal is what the student wants
  to learn about, not a course with a finish line. An issue that encodes a fixed ladder
  of steps is working against the product.

## Filing what you notice

Claude may open an issue autonomously, and should, for anything that will recur or that
a tool would solve more than once — provided the benefit outweighs the cost of building
it.

The strongest issues come from doing the work: a doc claim that quietly became false, a
gate that passes without looking at what it was meant to check, a comment pointing at a
note that does not exist. Findings are cheap to lose. A `bug` is always filable — the
test above is about whether something is worth *building*, never about whether a defect
is worth *recording*.

**File rather than fix** when the thing found is outside the branch in hand. A branch
that grows to cover everything it noticed is a branch nobody can review. When the user
postpones something that must still happen, offer the issue then and there.

**Do not transcribe a vague ask.** The idea must be clear to both sides first. Surface
the gaps, challenge the assumptions, reach shared understanding — *then* write.

## Labels

**One type label, plus at most one stage label.** The same nine are used across all of
the user's repos, so an issue reads the same wherever it was filed.

**Type — one:**

- `architecture` — the project's structure and conventions: a layer boundary, the
  Pydantic ↔ Flutter contract, where a responsibility is allowed to live.
- `infrastructure` — the tools and guardrails around how we write: a `Makefile` gate, a
  lint rule, a CI workflow, a test harness.
- `bug` — something is broken.
- `documentation` — documentation.
- `foundation` — groundwork the app already assumes but does not have yet. The app
  start that pretends every user has a goal is the shape of this one.
- `feature` — a new capability or resource, built on top of all of that.

The question that separates the first three is **what the change is about**: the shape of
the product is `architecture`, the machinery that constrains how it gets written is
`infrastructure`, and something merely missing rather than wrong is `foundation`.

**Stage — at most one, and its absence means ready:**

- `planning` — **never started.** It carries both "we do not yet know how" and "nobody has
  decided this is worth doing"; both are the user's call.
- `human` — cannot be finished by an agent alone (a GCP console step, an OAuth consent
  screen, a judgement of how a screen feels). **Treat as not-ready.**

**`minor`** — ~30 lines or fewer, small enough to ride along in another issue's pull
request. A size marker, not a type.

No amount of the issue looking startable overrides a stage label, and no amount of it
looking vague substitutes for one. **The judgement lives in the label**, so put it on
honestly: a Claude-written issue **must** carry one if it is a breaking change, changes
what the student sees, proposes a structural change, or needs a call the user has not
made. A `bug` usually should **not** — the deciding already happened when it broke.

## Priority

**`architecture` → `infrastructure` → `bug` → `foundation` → `feature`.**
`documentation` never waits its turn.

That is "foundations come first" as an order: if the way we build is not solid, that
halts everything downstream. Then what is broken. Then what the app assumes and lacks.
Then what is new. Priority orders what gets **merged**, not what gets **worked**.

## Relationships

Use GitHub's **Blocked by / Blocks**, and **sub-issues** when one is literal groundwork
for another. **The dependency graph is the plan** — there are no rigid batches.

**Do not split for parallelism.** Split by responsibility. Sub-issues that all land in
the same file are one issue; `issue-batch` names the files here that everything collides
in. In particular, **never split a payload change into a `[BE]` and an `[FE]`** — the
Flutter side is hand-mirrored and no gate holds the two halves together. That is one
`[FS]` issue.

If a `planning` issue would change how another is implemented, mark that other one
**blocked by** it.

## Closing

The pull request's description opens with `Closes #<number>` — and **check the number**.
A typo'd `Closes #N` closes the wrong issue or none, silently, and nothing verifies it.
