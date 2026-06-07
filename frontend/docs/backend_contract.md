# Backend endpoints

> Spec for the GoalGetter backend (FastAPI). Derived from the frontend mocks
> (`frontend/lib/features/**/debug/mock_*.dart`) — the frontend currently runs
> on those fixtures. We'll implement the services from this doc, then cover them
> with tests (TDD).

**Conventions**

- Prefix: `/api/v1` (e.g. `GET /me` → `GET /api/v1/me`).
- Auth: `Authorization: Bearer <access_token>` on everything **except**
  `/auth/signup`, `/auth/login`, `/auth/refresh`.
- Field names are snake_case (the Dart client generator maps them to camelCase).
- Times are ISO-8601. Status codes and error shapes are intentionally **omitted**
  (we'll pin those down when writing tests).
- "Active goal" = `students.current_goal_id`. Goal-scoped reads (`/home`,
  `/resources`, `/tutor/*`) use it implicitly — no `goal_id` in the URL.
- ⚙️ marks an endpoint that kicks off a **service** (LLM / scoring) we'll build
  separately.

**Legend:** ✅ implemented & tested · ⬜ to build

---

## Auth — ✅ implemented & tested
Router: `/api/v1/auth`. All of this exists already; do **not** rebuild.

- **`POST /auth/signup`** — sign up or sign in with a Google token (creates the
  account if new).
  request: Google token in `Authorization` header (no body) · response: `token_response`
- **`POST /auth/login`** — log in an existing user with a Google token.
  request: `oauth2_request` · response: `token_response`
- **`POST /auth/refresh`** — rotate tokens (refresh-token rotation).
  request: `token_refresh_request` · response: `token_refresh_response`
- **`POST /auth/logout`** — revoke a refresh token.
  request: `token_refresh_request` · response: none
- **`DELETE /auth/account`** — delete the signed-in user's account.
  request: none · response: none

> Note: a real `logout` exists server-side even though the frontend currently
> just discards its token. Refresh tokens live 30 days.

---

## User — ⬜

- **`GET /me`** — the signed-in user's profile + streak (drives the Profile header).
  request: none · response: `user_profile`
  - caveat: `current_streak` is user-wide; computed from lesson activity (no
    streak table needed unless we decide to cache it).

---

## Goals — ⬜

- **`GET /goals`** — all of the user's goals, full info (the Goals list screen
  reads everything at once; there is no per-goal GET).
  request: none · response: `goal[]`
  - `is_active` = `goal.id == students.current_goal_id`.

- **`POST /goals/objective-questions`** ⚙️ — step 1 of creation: validate the
  prompt is a real goal, then generate clarifying multiple-choice questions.
  request: `{ "prompt": "..." }` · response: `objective_question[]`
  - services: goal validation (reject non-goals) + question generation (LLM).
  - each question has exactly 4 options.

- **`POST /goals/study-plan`** ⚙️ — step 2: generate a short study-plan preview.
  request: `{ "prompt": "...", "answers": objective_answer[] }`
  response: `{ "goal_name": "...", "description": "...(markdown)" }`
  - caveat: stateless preview — nothing is persisted here.

- **`POST /goals`** ⚙️ — step 3: create the goal from the same inputs as the
  preview. Becomes the active goal (`current_goal_id`).
  request: `{ "prompt": "...", "answers": objective_answer[] }` · response: `goal`
  - caveat: regenerates from the inputs (not handed the previewed plan), so the
    stored goal may differ slightly from the preview. Also triggers the first
    lesson-bank generation (see Lessons).

- **`PUT /goals/{goal_id}/set-active`** — set `students.current_goal_id`.
  request: none · response: `{ "goal_id": "..." }`

- **`DELETE /goals/{goal_id}`** — delete a goal and its data.
  request: none · response: none

---

## Home — ⬜

- **`GET /home`** — dashboard for the active goal: rating, streak, recent
  lessons, and the elo-over-time series.
  request: none (uses `current_goal_id`) · response: `home_dashboard`
  - caveat: `elo_history` is one point per day, oldest first; the client filters
    to 7/30/90 days. `recent_lessons` newest first.

---

## Lessons — ⬜

- **`POST /goals/{goal_id}/lessons`** — open a lesson; returns a pre-built set of
  questions.
  request: none · response: `{ "lesson_id": "...", "questions": multiple_choice_question[] }`
  - caveat: questions are **not** generated on request. A background/cron job
    pre-generates a per-goal question bank based on the user's performance
    (how many to make, and whether to reuse questions from the user or similar
    goals). This endpoint just allocates the next set and opens an attempt.
  - `correct_answer_index` **is** included (the frontend grades inline; we accept
    that a determined user could read it via devtools).

- **`POST /goals/{goal_id}/lessons/{lesson_id}/answers`** ⚙️ — submit answers;
  returns the result.
  request: `{ "answers": lesson_answer[] }` · response: `lesson_evaluation`
  - services: score the attempt, update the goal's elo, update the streak.

---

## Tutor — ⬜
Scoped to the active goal (`current_goal_id`).

- **`GET /tutor/messages`** — chat history, paginated, ordered by `created_at`
  **descending** (client reverses for display).
  params: `cursor` (or `page`), `limit` · request: none · response: `chat_message[]`

- **`POST /tutor/messages`** ⚙️ — send a user message; get the tutor's reply.
  request: `{ "message": "..." }` · response: `chat_message` (the reply)
  - service: LLM chat completion. Persists both the user message and the reply.

- **`POST /tutor/messages/{message_id}/like`** — toggle the "liked" flag on a
  message.
  request: `{ "is_liked": true }` · response: `chat_message` (updated)

---

## Resources — ⬜

- **`GET /resources`** — curated resources for the active goal, grouped by kind.
  request: none (uses `current_goal_id`) · response:
  `{ "youtube": resource_item[], "books": resource_item[], "websites": resource_item[] }`
  - caveat: for now resources can be a static/seeded list per goal; no LLM
    needed unless we want generated suggestions later.

---

## Schemas

```jsonc
// ── Auth (implemented) ──
student_response        { "id": "...", "google_id": "...", "email": "...", "name": "..." }
oauth2_request          { "access_token": "<google token>" }
token_response          { "access_token": "<jwt>", "refresh_token": "...", "student": student_response }
token_refresh_request   { "refresh_token": "..." }
token_refresh_response  { "access_token": "<jwt>", "refresh_token": "..." }

// ── To build ──
user_profile            { "id": "...", "name": "...", "email": "...", "current_streak": 7 }

goal                    { "id": "...", "name": "...", "description": "...",
                          "current_elo": 920, "is_active": true, "created_at": "2026-05-31T00:00:00Z" }

objective_question      { "question": "...", "options": ["a","b","c","d"] }  // exactly 4
objective_answer        { "question": "...", "answer": "<the selected option>" }  // unselected options omitted

home_dashboard          { "goal_name": "...", "current_elo": 920, "current_streak": 7,
                          "recent_lessons": [ recent_lesson ],   // newest first
                          "elo_history":    [ elo_point ] }       // one/day, oldest first
recent_lesson           { "lesson_id": "...", "date": "2026-06-06", "accuracy": 90.0,
                          "elo_delta": 10, "duration_seconds": 137 }
elo_point               { "date": "2026-05-31", "elo": 854 }

multiple_choice_question{ "id": "q1", "question": "...", "choices": ["...","..."],
                          "correct_answer_index": 0 }
lesson_answer           { "question_id": "q1", "choice_index": 0, "seconds_spent": 12 }
lesson_evaluation       { "total_seconds_spent": 142, "student_accuracy": 80.0, "elo": 14 }

chat_message            { "id": "...", "message": "...", "sender": "tutor",  // "user" | "tutor"
                          "is_liked": false, "created_at": "2026-06-06T09:00:00Z" }

resource_item           { "name": "...", "description": "...", "url": "https://...",
                          "image_url": "https://..." }
```

---

## Cross-cutting notes
- **elo** everywhere (the old SDK used `xp`). Elo is **per-goal**, stored as
  `goals.elo` (the user's rating *for that goal*); `goal.current_elo` and
  `home_dashboard.current_elo` read from it. `lesson_evaluation.elo` is the
  signed change applied to it for that lesson. Streak stays **per-user**.
- **`students.current_goal_id`** is the single source of truth for the active
  goal — drives `/home`, `/resources`, `/tutor/*`, and each goal's `is_active`.
- **Streak** is just `current_streak` (a number) on `/me` and `/home`. No streak
  table/endpoint, no weekly breakdown.
- **`chat_message`** gains `is_liked` and `created_at` (the frontend model needs
  both — like toggle + descending-time pagination).
- **LLM-backed** (⚙️ via `llms.py`): objective-questions, study-plan, create
  goal, tutor reply. The lesson question bank is built by a separate background
  job, not at request time.
