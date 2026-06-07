# How the frontend talks to the backend (the plan)

> Status: **plan / not implemented yet.** This describes the workflow we intend
> to adopt once the backend endpoints exist. Today the frontend runs on mock
> data (see the `debug/` folders and `mock_*` files).

## Wait — isn't this the same as the old `client_sdk`? (Yes.)

Be clear-eyed about this: **this is the same flow we already had.** The old
`client_sdk` / `package:openapi` was made the exact same way — pull
`openapi.json`, generate a Dart client, use it in the frontend. We are not
inventing a new approach; we are getting back onto the one we left.

So what actually went wrong before, and what changes:

- **What went wrong: the copy went stale.** The old SDK was generated against an
  *older* version of the backend. The app moved on, nobody regenerated, and the
  SDK stopped matching what the screens needed. The approach didn't fail — the
  photocopy was just out of date. That's why we tore it out and switched to
  mocks.
- **Why we're on mocks right now:** the new backend's endpoints don't exist yet,
  so there's no correct `openapi.json` to generate from. You can't photocopy a
  menu the kitchen hasn't written. Mocks are a temporary stand-in, not a
  different philosophy.
- **The only real changes going forward:**
  1. A **lighter generator tool** (a Dart/build_runner one instead of the old
     Java tool) — less to install and maintain. Tooling change, not flow change.
  2. **Regenerate as a habit** so the copy never drifts again. That's the actual
     lesson from last time — discipline, not architecture.
  3. **Keep the mock layer in between** (the thin providers) so the app still
     runs on mocks when the backend is down or mid-change.

Everything below describes that same flow, written so it doesn't go stale this
time.

## The one idea to remember

**The backend is the source of truth. The frontend copies from it — automatically.**

The backend describes what it offers. A tool reads that description and writes
the Dart code the frontend uses to make the calls. We never hand-write that
plumbing, and we never describe the API twice.

Analogy: the backend is a kitchen that prints its own menu. The frontend is a
waiter who photocopies the menu so they always know exactly what can be ordered
and how. Change a dish in the kitchen → re-photocopy → the waiter is up to date.

## The direction of the flow

```
  BACKEND (you write this)              FRONTEND (auto-generated)
  ──────────────────────────           ──────────────────────────
  1. Write the endpoint +     ┐
     its data shapes (Python,  │
     FastAPI + Pydantic)       │
                               ▼
  2. FastAPI auto-creates a    ┐
     "menu" file describing    │   3. A generator reads the menu
     everything:               ├──────►  and writes Dart code:
     /api/v1/openapi.json      │         - models (the data shapes)
                               ┘         - a client (the call methods)
                                              │
                                              ▼
                               4. Our screens call that generated
                                  client to get real data.
```

Steps 2 and 3 are automatic. The only real work is **step 1** (writing the
endpoints) and the logic inside them.

## What is and isn't automatic

| Thing | Who/what does it |
| --- | --- |
| Describe the API (the "menu") | **Automatic** — FastAPI produces `openapi.json` |
| Frontend models + call code | **Automatic** — the generator writes the Dart |
| What each endpoint actually *does* | **You**, in the backend |
| Backend tests | **You** — the generator does not write tests |
| Frontend screens/widgets | **You** — unchanged by the generator |

The generator only produces *plumbing*. It never writes real behavior, and it
never writes tests. The plumbing is the boring part we're handing off.

## The day-to-day loop, once it's set up

1. Add or change an endpoint in the backend.
2. Run the backend; it serves an updated `openapi.json`.
3. Run one command on the frontend to regenerate (same command we already use
   for other generated code: `dart run build_runner build`).
4. If anything no longer lines up, the Dart compiler points at the exact spots
   to fix. Update those, done.

That's the whole maintenance story: **change backend → regenerate → fix what
the compiler flags.** No manual syncing.

## Where this plugs into the current code

We deliberately built the app so this swap is cheap later:

- **The thin `*_controller.dart` providers are the swap point.** Today they
  return mock data; later they call the generated client. The screens that use
  them don't change at all.

  ```dart
  // today
  final goalsListControllerProvider =
      FutureProvider((ref) async => getMockGoals());

  // after wiring (illustrative)
  final goalsListControllerProvider =
      FutureProvider((ref) async => ref.read(apiProvider).getGoals());
  ```

- **The hand-written model files** (`Goal`, `UserProfile`, `StudyPlan`,
  `lesson_models`, …) were a stand-in because we had no usable API. Once the
  real models are generated, most of these get retired. We keep one only if it
  carries actual behavior (a computed value, some view logic), and then as a
  small add-on rather than a duplicate.

- **The `mock_*` files stay.** They're still useful as test fixtures and for
  building UI offline without the backend running.

## Tooling choice (for when we implement)

- Generate using a **build_runner-based** Dart generator (e.g. `swagger_parser`)
  so it runs with the same `dart run build_runner` flow we already use — no
  extra Java/Docker toolchain to install or maintain.
- Avoid the Java `openapi-generator-cli`. That's what produced the old, now
  deprecated `package:openapi`; it needs a heavier toolchain and was only a
  problem before because it was generated against the *old* backend and went
  stale.
- For an API this small, use the generated models **directly** in the UI — no
  extra translation layer between "API shape" and "app shape."

## Why this is worth it here

The usual catch with this approach is "now you maintain a description file by
hand." We don't — FastAPI writes `openapi.json` for us from code we already
write. So we get the safety (frontend can't silently drift from the backend)
without the upkeep. The only ongoing cost is running one regenerate command
when the backend changes.
