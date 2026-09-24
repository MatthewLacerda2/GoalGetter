# Backend endpoints

> Spec for the GoalGetter backend (FastAPI). Derived from the frontend mocks
> (`frontend/lib/features/**/debug/mock_*.dart`) — the frontend currently runs
> on those fixtures. We'll implement the services from this doc, then cover them
> with tests (TDD).

**Conventions**

- Prefix: `/api/v1` (e.g. `GET /me` → `GET /api/v1/me`).
- Auth: `Authorization: Bearer <access_token>` on everything **except**
  `/auth/signup`, `/auth/login`, `/auth/dev-login`, `/auth/refresh`.
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
- **`POST /auth/dev-login`** ✅ — **dev only** (#51): sign in as a fictitious
  student, no Google. request: `{ "name": "Claude" }` · response: `token_response`
  - creates or reuses the student `Fictitious <name>` (the prefix is not doubled),
    with `google_id` = the slug (`fictitious-claude`) and email
    `<slug>@fictitious.invalid`. **The name prefix is the only fictitious
    marker** — no database flag (decided).
  - only when the `DEV_LOGIN` setting is true (default false); off ⇒ 404, and the
    route is left out of the OpenAPI schema.
  - `make claude-token` calls it for `Claude` on the running backend
    (`BACKEND_PORT`, default 8001) and writes the access token to the gitignored
    `.claude/token`. The token lasts 30 min and dies with any backend restart.
  - `DEV_LOGIN` also widens CORS to loopback and Tailscale origins on any port
    (`backend/core/cors.py`); production stays on the exact origin list.

> Note: the frontend calls `logout` on sign-out (best effort), then deletes
> every stored key. Access tokens live 30 minutes, refresh tokens 30 days; the
> app's `ApiClient` refreshes once on a 401 and replays the request.

---

## User — ✅ implemented & tested (#56, backend and app)

- **`GET /me`** — the signed-in user's profile + streak (drives the Profile header).
  request: none · response: `user_profile`
  - `member_since` is `students.created_at`.
  - `current_streak` is user-wide; computed from lesson activity, no streak
    table (see **Streak** under the cross-cutting notes).

---

## Goals — ✅ implemented & tested

- **`GET /goals`** ✅ — all of the user's goals, full info (the Goals list screen
  reads everything at once; there is no per-goal GET).
  request: none · response: `goal[]`, **newest first** (`created_at`)
  - `is_active` = `goal.id == students.current_goal_id`. It is the only goal
    "status" there is.
  - `current_elo` reads `goals.rating`. `updated_at` is bumped by any change to
    the goal row (SQLAlchemy `onupdate`), the rating after a lesson included, so
    it reads as "last studied". Activating a goal changes `students`, not the
    goal, so it does not move `updated_at`.

- **`POST /goals/objective-questions`** ⚙️ ✅ — step 1 of creation: validate the
  prompt is a real goal, then generate clarifying multiple-choice questions.
  request: `{ "prompt": "..." }` · response: `objective_question[]`
  - services: goal validation (reject non-goals) + question generation (LLM).
  - validation is **one** Gemini call returning three booleans — makes_sense,
    is_harmless, is_achievable — plus a `reasoning` string. Any false ⇒ 400 with
    that reasoning (the app shows it to the user and stops). Only if all three
    pass do we make the second call for the questions.
  - **exactly 5 questions**, 4 options each, no correct answer. Each probes one
    fixed dimension: familiarity, interests, hands-on practice, theory,
    preferred learning style. (The frontend mock still shows 6 — mock is wrong.)
  - **PUBLIC** (no auth) + rate-limited 20/min, so anyone can try the app.

- **`POST /goals/study-plan`** ⚙️ ✅ — step 2: preview what the goal will be.
  request: `{ "prompt": "...", "answers": objective_answer[] }`
  response: `{ "goal_name": "...", "description": "...(markdown)" }`
  - stateless preview — nothing is persisted here.
  - **PUBLIC** + rate-limited, same as step 1.
  - ⚠️ **decided, not yet done:** this should describe *what the goal covers* so
    the user can say "yes, that's what I want" — NOT a study plan. Users are not
    able to judge their own study plan; they can judge whether we understood
    their goal. Endpoint name can stay; the prompt must change.

- **`POST /goals`** ⚙️ ✅ — step 3: commit the goal the user approved.
  request: `GoalCommitRequest` (prompt, answers, **and the approved goal_name +
  description**) · response: `goal` + `introduction_screen_data`
  - **AUTHED.** Steps 1–2 are public; on "Generate" the app signs in with Google,
    calls `/auth/signup` (idempotent create-or-return ⇒ JWT) and replays this
    request with the token. Ownership = the authenticated student.
  - does **not** re-generate the goal: it persists exactly the text the user
    approved, so what they said yes to is what they get (and it saves a call).
  - the only synchronous Gemini call here is the **introduction screens** (fast
    model): 3–5 `{icon, title, text}` shown while background setup runs. `icon`
    is a fixed 15-value enum so Gemini cannot hallucinate an icon name.
  - sets `students.current_goal_id`, then fires the background jobs below.

- **`PUT /goals/{goal_id}/set-active`** ✅ — set `students.current_goal_id`.
  request: none · response: `{ "goal_id": "..." }`

- **`DELETE /goals/{goal_id}`** ✅ — delete a goal and its data.
  request: none · response: 204, no body
  - the database cascades: `ON DELETE CASCADE` takes the goal's rows
    (resources, lessons, questions…), `SET NULL` clears `current_goal_id` when the
    active goal goes. No goal becomes active in its place; the client decides
    where to land. **Student contexts survive**: they hang off the student, not
    the goal (#87), and they are progression history.

Both `{goal_id}` routes answer **404** for a missing goal *and* for someone
else's (`get_owned_goal`), so a goal's existence never leaks.

---

## Home — ✅ implemented & tested (#56, backend and app)

- **`GET /home`** — dashboard for the active goal: rating, streak, recent
  lessons, and the elo-over-time series.
  request: none (uses `current_goal_id`) · response: `home_dashboard`
  - **404** `No active goal` without one (`get_active_goal`, as `/resources`);
    the app shows its empty state with a way to create a goal.
  - `recent_lessons`: finished lessons only, newest first, at most **10** (the
    screen shows 4).
  - `elo_history`: one point per day that had a finished lesson, oldest first,
    the `elo_after` of that day's last lesson; the whole history, the client
    filters to 7/30/90 days.
  - Dates are the server's local date of `lessons.finished_at`.

---

## Lessons — ✅ implemented & tested (#55, backend and app)

- **`POST /goals/{goal_id}/lessons`** — open a lesson from the goal's question
  bank. 201.
  request: none · response: `{ "lesson_id": "...", "questions": multiple_choice_question[] }`
  - questions are **not** generated on request: the bank is built by the lesson
    job (see Background jobs). This endpoint picks the next set and opens a
    lesson (`lessons` row, served ids in order).
  - **selection**, in this order until the lesson is full
    (`QUESTIONS_PER_LESSON` = 5, `utils/envs.py`): 1. questions whose **latest**
    answer was wrong, most recent first; 2. questions never answered, oldest
    first; 3. everything else, least recently answered first. Written once, in
    `services/lessons/selection.py`. The embedding columns are unused, and
    nothing will be shared between students (see **No reuse between students**).
  - empty bank ⇒ **409** `"Lessons are still being prepared"`. Not the
    student's goal ⇒ 404.
  - every call opens a new lesson; an unanswered one is simply left open.
  - `correct_answer_index` **is** included (the frontend grades inline; we accept
    that a determined user could read it via devtools). The server re-grades.

- **`POST /goals/{goal_id}/lessons/{lesson_id}/answers`** — submit the answers
  all at once; returns the result.
  request: `{ "answers": lesson_answer[] }` (at least one) · response: `lesson_evaluation`
  - graded **server-side** from the stored correct index; nothing the client
    says about correctness is read. `student_accuracy` is over every question
    **served**: one left out counts as wrong. Time is self-reported.
  - stores one `lesson_answers` row per question (the first attempt; the
    review round is never submitted), then the lesson's `finished_at`,
    `total_seconds`, `accuracy`, `elo_delta`, `elo_after`.
  - `elo` is **random** (±20) until the elo design (#62): one function,
    `services/lessons/elo.py`. It is added to `goals.rating`.
  - lesson already answered ⇒ **409**. A question not served in this lesson, or
    the same one twice ⇒ **422**. Lesson not in this goal ⇒ 404. Streak: #56.

---

## Tutor — ✅ implemented & tested
Scoped to the active goal (`current_goal_id`); no active goal ⇒ 404 `No active goal`.
The API speaks in **exchanges**, not single messages: one row of `chat_messages`
is the student's prompt plus the tutor's reply, and the reply is Gemini's array
of short strings (WhatsApp-style bubbles). The client expands one exchange into a
user bubble plus one tutor bubble per `responses` entry.

- **`GET /tutor/messages`** ✅ — the active goal's exchanges, **newest first**
  (client reverses for display).
  params: `before` (a `created_at`; only older exchanges), `limit` (default 20,
  max 50) · request: none · response: `chat_exchange[]`. Next page: pass the last
  item's `created_at` as `before`.

- **`POST /tutor/messages`** ⚙️ ✅ — send a message; get the stored exchange (201).
  request: `{ "message": "..." }` · response: `chat_exchange`
  - service: `services/gemini/chat/` via `run_gemini` (a Gemini `APIError` keeps its
    status code). Gemini gets the goal's name and description, **the student's**
    still-valid contexts (all of them — a context is not goal-scoped, #87; what is
    specific to this goal already reaches the prompt as its name and description),
    and the last `HISTORY_WINDOW` (10) exchanges oldest first as alternating
    user/model turns, then the new message. Older memory is the student contexts'
    job, not the window's.

- **`PUT /tutor/messages/{message_id}/like`** ✅ — set (not toggle) the like on the
  tutor's reply; the heart sits on the reply's last bubble.
  request: `{ "is_liked": true }` · response: `chat_exchange` (updated). An
  exchange outside the active goal (someone else's, or another goal's) ⇒ 404.

---

## Resources — ✅ implemented & tested

- **`GET /resources`** ✅ — curated resources for the active goal, grouped by kind.
  request: none (uses `current_goal_id`) · response:
  `{ "youtube": resource_item[], "books": resource_item[], "websites": resource_item[] }`
  - `pdf` → `books`, `webpage` → `websites`. `url` is the stored `link`.
  - no active goal ⇒ **404 `No active goal`** (`get_active_goal`). A goal whose
    background job has not finished yet has three empty lists, not an error.

### Resource generation (background job) — ✅

Kicked off fire-and-forget by `POST /goals`; the introduction screens exist to
buy time for it. Never fails the request that started it. Also intended to re-run
on its own schedule later (on a significant skill jump, or monthly).

1. Ask Gemini (premium model, Google Search grounding) for 3 YouTube + 3
   webpages + 3 PDFs, then a second call reshapes that text into JSON.
2. **Validate every link** (see below) — anything unconfirmed is dropped
   silently. No 4xx: nobody is waiting on this.
3. Drop links this goal already has, embed the descriptions, store the rest.

**Link validation rules**
- *webpage* — must answer a request at all.
- *pdf* — must answer AND be a real PDF (`content-type: application/pdf`, or a
  `.pdf` path as fallback since some hosts serve octet-stream).
- *youtube* — must resolve through the **YouTube Data API v3** to a real item:
  a video must be `public`, and the channel/video must have a picture, which we
  store as `image_url`. Needs `YOUTUBE_API_KEY`; without it YouTube links are
  dropped. Handles `/watch?v=`, `youtu.be/`, `/shorts/`, `/embed/`,
  `/channel/UC…` and `/@handle`.

**`resources.link` is deliberately NOT unique.** Two students may legitimately be
recommended the same channel, and reusing another student's verified resources is
a card we want to keep playable. Dedupe is **per-goal** only.

---

## Background jobs

Fire-and-forget, spawned on the running loop, errors logged not raised.

| Job | Trigger | State |
| --- | --- | --- |
| **Resource scraping** | goal created; later on skill jump / monthly | ✅ built |
| **Lesson generation** | goal created (first the student context, then the first question bank from the student's still-valid contexts + this goal); later a nightly job (#89) | ✅ first bank · ⬜ nightly |
| **Student context ("memories")** | after onboarding, then periodically | ✅ initial, from every goal the student has · ⬜ periodic service written, nothing calls it |

**Scheduling rule for memories** (user's intent, not yet implemented): check every
student **daily**, but only regenerate if **≥3 days since the last generation**
AND the student actually chatted or did a lesson in between. No activity ⇒ no
job, no tokens spent.

**History — the old nightly schedule (deleted 2026-09-21).** `backend/core/scheduler.py`
wired four APScheduler daily crons: lesson creation (04:30), lesson context
(02:00), chat context (03:00), mastery evaluation (05:00). All four job modules
had already been deleted in Major/refactor (#41), so every import was broken; the
file has now been removed too. Kept here as design history — note it split memory
generation into **two** jobs (chats and lessons separately) and had a
**mastery evaluation** job the current plan does not mention.

**Decided: collapse to two nightly jobs.** One updates context/memories, one
creates lessons — in that order, because lesson creation consumes the memories.
Four jobs was over-splitting. No scheduler runs today.

**Spirit: progression follows the student, not a syllabus.** Early prompting
framed a goal as a fixed ladder of steps (chess: piece movement → endgames →
tactics → openings). That is the wrong frame. A goal names *what the student
wants to learn about*, not a course with a finish line — someone learning
calculus is not taught until they'd graduate, they are taught continuously, and
progression is measured against **them**, not against a curriculum. This is a
guiding spirit for prompt-writing, not a mechanically enforced rule.

**Student context** is the app's memory of the learner, stored **per student**
as two texts: `state` (what they know / where they are) and `metacognition`
(how they think). It carries no `goal_id` (#87): what the app knows about a
person does not change when they switch from law to history, and one context per
goal paid Gemini once per goal to say much the same thing. The generator reads
**all** of the student's goals (name + description) — and, for the periodic
revision, their recent lessons and chats across every goal — and writes one
reading of the learner.

Its readers pass it on whole: the **tutor** sends the student's still-valid
contexts, and **question generation** takes the same contexts plus the goal it
is generating for. Anything goal-specific reaches a prompt as the goal's own
name and description, never through the context.

Two services exist — one builds the first impression from the onboarding
answers, one revises it from recent lesson results and chat history (written,
not yet scheduled). `is_still_valid` retires a stale context **without
deleting it**: kept for progression history and data science. The user is meant
to be able to read what the app has written about them.

**No reuse between students.** Nothing generated for one student is ever served
to another — not questions, not resources, not contexts. Embedding columns exist
for similarity work *within* a student, and the lesson-question embeddings that
were once meant to share questions across students are not going to be used that
way. The project has to be good without it (the user, 2026-09-23).

---

## Decisions (2026-09-21)

Decided in conversation; recorded here so they survive the session.

1. **Study plan becomes a goal description.** Users can't judge a study plan;
   they can judge whether we understood the goal. Prompt change, pending.
2. **`resources.link` is not unique** (see Resources). Per-goal dedupe only;
   reusing another student's verified resources is **closed** (#87) — nothing is
   reused between students, resources included.
3. **Store validation outcomes, pass *and* fail.** Cheap, and impossible to
   reconstruct later. Note what it actually measures: **how often Gemini invents
   links**, not user behaviour. Build it *before* switching to Google search, so
   there's a baseline to compare against. ⬜ not built.
4. **Move resource search to Google, keep Gemini for judgment.** Gemini writes
   the search queries → Google Custom Search JSON API returns *real* URLs →
   Gemini ranks and describes the results it gets back. Cheaper (results are
   input tokens, not output), more deterministic, and no URL can be invented.
   Validators stay as the safety net. YouTube still needs the Data API either
   way. ⬜ not built; `customsearch.googleapis.com` not yet enabled.
5. **Embedding columns stay nullable** everywhere — generating them is never
   obligatory. Present on: chat messages (prompt + response), goals, resources,
   student context (state + metacognition), lesson questions. ~~The
   lesson-question one exists to **reuse questions across students**~~ —
   **closed (#87, 2026-09-23): nothing is ever reused between students.** See
   **No reuse between students** above.
6. **Model split.** Two models, always: a **fast** one (cheaper, less sharp) and a
   **premium** one. They may be the same name when only one is worth using; the
   split is the rule, not the two names. Where each goes (the user, 2026-09-24):
   **premium** for onboarding end to end — goal validation, the objective
   questions, the study plan, the introduction screens — and for the student
   context, because both decide what the student gets for a long time;
   **fast** for what is generated constantly: the tutor's replies, lesson
   questions, and the resource search. Model names live in `backend/utils/envs.py`
   and need a bump roughly monthly — last bumped 2026-09-21 to
   `gemini-3.5-flash-lite` / `gemini-3.8-flash`.

### Build order agreed
1. Backend correct & tested (mocked Gemini) ← we are here
2. Integrate the screens against it
3. Lock schemas, generate the **first** Alembic migration, stop dropping the DB
4. Real Google OAuth, then the Cloudflare tunnel

> Until step 3 the database **drops its whole schema on every backend start**.
> There are no migrations yet (Alembic is scaffolded, `versions/` is empty).

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
user_profile            { "id": "...", "name": "...", "email": "...",
                          "member_since": "2026-05-31T00:00:00Z", "current_streak": 7 }

goal                    { "id": "...", "name": "...", "description": "...",
                          "current_elo": 920, "is_active": true, "created_at": "2026-05-31T00:00:00Z",
                          "updated_at": "2026-06-06T09:00:00Z" }

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

chat_exchange           { "id": "...", "prompt": "...", "responses": ["...", "..."],
                          "is_liked": false, "created_at": "2026-06-06T09:00:00Z" }

resource_item           { "name": "...", "description": "...", "url": "https://...",
                          "image_url": "https://..." }   // image_url null except on youtube
```

---

## Cross-cutting notes
- **elo** everywhere (the old SDK used `xp`). Elo is **per-goal**, stored as
  `goals.rating` (the user's rating *for that goal*); `goal.current_elo` and
  `home_dashboard.current_elo` read from it. `lesson_evaluation.elo` is the
  signed change applied to it for that lesson, in one atomic `UPDATE`
  (`GoalRepository.add_to_rating`, #72), whose result is `lessons.elo_after`.
  Streak stays **per-user**.
- **`students.current_goal_id`** is the single source of truth for the active
  goal — drives `/home`, `/resources`, `/tutor/*`, and each goal's `is_active`.
- **Streak** is just `current_streak` (a number) on `/me` and `/home`. No streak
  table/endpoint, no weekly breakdown. The rule (`services/lessons/streak.py`):
  consecutive days with at least one finished lesson on any goal, counted back
  from today, or from yesterday when there is none today yet. Days are the
  server's local date; time zones can come later.
- **`chat_exchange`** replaced the mock-derived per-message `chat_message`
  (#54): one exchange = prompt + reply bubbles, with `is_liked` and `created_at`.
- **LLM-backed** (⚙️ via `llms.py`): objective-questions, study-plan, create
  goal, tutor reply. The lesson question bank is built by a separate background
  job, not at request time.
