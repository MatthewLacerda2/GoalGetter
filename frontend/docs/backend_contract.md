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
  - `current_streak` is user-wide; computed from answer activity, no streak
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
  - stores the prompt and the onboarding answers (`onboarding_questions`), sets
    `students.current_goal_id`, then fires the **student chain** below with the
    student's id — the chain reads the onboarding back, it is not handed it.

- **`PUT /goals/{goal_id}/set-active`** ✅ — set `students.current_goal_id`.
  request: none · response: `{ "goal_id": "..." }`

- **`DELETE /goals/{goal_id}`** ✅ — delete a goal and its data.
  request: none · response: 204, no body
  - the database cascades: `ON DELETE CASCADE` takes the goal's rows
    (resources, questions and their answers…), `SET NULL` clears `current_goal_id` when the
    active goal goes. No goal becomes active in its place; the client decides
    where to land. **Student contexts survive**: they hang off the student, not
    the goal (#87), and they are progression history.

Both `{goal_id}` routes answer **404** for a missing goal *and* for someone
else's (`get_owned_goal`), so a goal's existence never leaks.

---

## Home — ✅ implemented & tested (#56, backend and app)

- **`GET /home`** — dashboard for the active goal: rating, streak and recent
  lessons.
  request: none (uses `current_goal_id`) · response: `home_dashboard`
  - **404** `No active goal` without one (`get_active_goal`, as `/resources`);
    the app shows its empty state with a way to create a goal.
  - `recent_lessons`: the answers of this goal **grouped by their `lesson_id`**,
    newest first, at most **10** (the screen shows 4). Accuracy and seconds are
    counted over the group; there is no lesson row to read them off (#131).
  - Dates are the app's calendar date (`core/clock.py`) of the group's last
    answer.
  - **no `elo_history`, no per-lesson `elo_delta`.** They came off the `lessons`
    table, which is gone; the rating has no stored history until #62. The app
    shows no chart meanwhile, and each row ends with the day instead of an elo
    badge.

---

## Lessons — ✅ implemented & tested (#55, #131, backend and app)

**A lesson is a cut, not a row.** It is the questions chosen for this student at
this moment. There is no `lessons` table and there will not be one: serving
writes nothing, and what makes a lesson afterwards is the `lesson_id` the
backend mints over the answers when they arrive (#131).

- **`POST /goals/{goal_id}/lessons`** — open a lesson from the goal's question
  bank. 201.
  request: none · response: `{ "questions": multiple_choice_question[] }`
  - questions are **not** generated on request: the bank is built by the lesson
    job (see Background jobs). This endpoint picks the next set and stores
    nothing — so there is no `lesson_id` in the response, and nothing to resume.
  - **selection**, in this order until the lesson is full: 1. questions whose
    **latest** answer was wrong, most recent first; 2. questions never answered,
    oldest first; 3. everything else, least recently answered first. Written
    once, in `services/lessons/selection.py`, which also owns **how many** —
    the endpoint asks for a lesson and takes what it gets. The embedding columns
    are unused, and nothing will be shared between students (see **No reuse
    between students**).
  - the count is the flat `QUESTIONS_PER_LESSON` = 8 of #86 today. It stops
    being flat with #134: a lesson is two minutes, filled from the student's own
    answering pace, with a floor of six.
  - **the count is a cap, not a floor** (#86). A short bank serves what it has:
    the empty bank is the student who has just created a goal and is already
    answered with the 409 below, while a bank that is short but not empty means
    last night's generation came back thin — refusing there would turn one bad
    night at Gemini into a lost day of study. The bank only grows, so a short
    lesson repairs itself.
  - empty bank ⇒ **409** `"Lessons are still being prepared"`. Not the
    student's goal ⇒ 404.
  - `correct_answer_index` **is** included (the frontend grades inline; we accept
    that a determined user could read it via devtools). The server re-grades.

- **`POST /goals/{goal_id}/lessons/answers`** — submit the answers all at once;
  returns the result.
  request: `{ "answers": lesson_answer[] }` · response: `lesson_evaluation`
  - **the completeness rule of #86 is gone.** Nothing recorded what was served,
    so the backend cannot say "you left one out" and does not try: it grades
    what arrives. The app still sends the whole lesson in order
    (`lesson_controller.dart` returns to a gap rather than sending it), because
    that is the lesson the student did — not because the server insists.
  - graded **server-side** from the stored right index; nothing the client says
    about correctness is read. `student_accuracy` is over the answers submitted.
    Time is self-reported, per answer (`student_answers.total_seconds`) — that
    is what makes the two-minute target measurable.
  - stores one `student_answers` row per answer, all carrying **one fresh
    `lesson_id`** and their 0-based `position`. Nothing is overwritten: the same
    question answered five times is five rows, which is the history that says
    whether the student learned. `is_correct` is **not** stored — it is
    `selected_index == questions.right_answer_index`.
  - `elo` is **random** (±20) until the elo design (#62): one function,
    `services/lessons/elo.py`. It is added to `goals.rating` and returned, but
    not recorded anywhere per lesson.
  - an answer naming a question outside this goal's bank, or naming one twice
    in the same batch ⇒ **422**, and nothing is stored. An empty `answers` list
    ⇒ 422 (it would mint a lesson mark over nothing). Not the student's goal ⇒
    404. Streak: #56.
  - **no idempotency.** There is no lesson row to be "already answered", so a
    submit whose response was lost and then retried writes a second lesson. The
    app only retries on a failure it saw, and `_hasSubmittedAnswers` stops a
    double send inside one session.

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

### Resource generation (the chain's third step) — ✅

The last step of the student chain (see Background jobs), which `POST /goals`
kicks off fire-and-forget; the introduction screens exist to buy time for it.
Never fails the request that started it. It runs only after the student has a
context, and the nightly run asks for it on Mondays only (#89).

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

**There is one background job: the student chain** (`services/jobs/student_chain.py`,
#88). `run_student_chain(student_id)` runs three steps for one student, in this
order and never in parallel — Gemini is called one at a time, and each step reads
what the one before it wrote:

| Step | Reads | Writes |
| --- | --- | --- |
| **1. Context** | every goal of the student with its current frontier, plus either the stored onboarding or their recent lesson answers and tutor chats | `student_contexts` rows added, stale ones retired, `frontiers` moved on — possibly none of the three |
| **2. Questions** (per goal) | the goal's whole bank with its latest answers, the student's still-valid contexts, the goal and its **current frontier** | `questions`, and only when the bank is short |
| **3. Resources** (per goal) | the student's newest context, the goal, the links the goal already holds | `resources` |

`run_student_chain(student_id, with_resources=True)` — the one thing a caller
decides is the third step, because it is the one that is not wanted every time:
the nightly run buys resources once a week, goal creation wants them for a goal
that has none. Everything else a step reads for itself.

**Nothing tells a step whether this is the first run.** Each works out what it
needs from what it finds: no lesson answered yet (or no context left standing)
and step 1 writes the first impression from the onboarding, otherwise it revises
the newest context. An empty list of recent mistakes is a normal input, not a
special case. Goal creation's only particularity is that there is nothing to
read yet.

**The onboarding is stored, not passed.** `POST /goals` writes the student's
prompt and their answers to `onboarding_questions` (see
`repositories/onboarding_repository.py` for how a row encodes them) and fires the
chain with the student's id alone. An input that lives only in a function
argument dies with the call that carried it; these rows mean a chain that failed
tonight can be run again tomorrow.

**No resources without memory** (the user, 2026-09-23). Step 3 returns without
calling Gemini when the student has no valid context: a search made with no
reading of the learner returns what anyone would get.

**A failed step stops the chain and keeps what was already written.** Each step
commits its own work, so a context that cost a premium call survives a question
bank that failed after it. The steps that had not run yet do not run — a Gemini
failure is usually the rate limit or the quota, and firing the next calls
straight at it turns one failed step into three. The next run picks up where
this one stopped.

### The nightly run — who gets a chain tonight (#89)

**`backend/services/jobs/nightly.py`**, triggered by
**`backend/tools/nightly_run.py`**, which runs as the `nightly` service in
`docker-compose.yml`. It fires at **03:00 in `APP_TIMEZONE`**
(`clock.NIGHTLY_RUN_HOUR`, #92), and for each student in turn:

1. **skip unless they answered a question in the day the run is closing out** —
   no chain, no Gemini call, nothing. Chat activity does not count; only
   answers do.
2. run the chain's **context** step, then its **question** step;
3. **on Mondays**, run the **resource** step as well.

**"Today" is the 24 hours behind the run, not the calendar day**
(`clock.previous_nightly_run`). The run fires three hours into a day nobody has
studied yet, so reading the calendar date would skip every student who studied
the evening before — which is every student. The window is
`[previous 03:00, now]`. The rule "resources also need study in the last
seven days" is satisfied by construction: a student who reaches step 3 studied
within the last 24 hours.

**Students are processed one at a time**, so the Gemini calls stay serialized,
and a student whose chain raises is logged and left behind — the next student
still runs. That is where the chain's re-raise is caught.

**Why a separate process and not a scheduler in the app.** The API runs four
uvicorn workers, each its own process, so an in-process scheduler would fire
the same night four times. Electing a leader among them means a lock table and
a heartbeat. **Why a compose service and not the host's cron:** the deployment
is this machine's `docker compose up`, rebuilt from `main` on every merge, so a
service ships with the code that needs it and is reviewed with it; a cron entry
lives outside the repository and has to be installed by hand on any machine the
app is ever brought up on. The trade is that a **missed 03:00 is simply
missed** — there is no catch-up, because remembering when the job last ran
means a column, and none was asked for.

It **waits for the hour before it runs, never on startup**: `restart:
unless-stopped` plus a run on start would spend real quota on every deploy.

**By hand, for one student:** `make nightly ARGS='--student <id>'`, or
`--once` for the whole night. Same code, same decisions, every one of them
logged — including the skips, with the reason.

### What the context step asks for (#90)

The nightly review is **not a rewrite**. Regenerating the whole context every
night paid a premium call to produce much the same paragraphs. So
`gemini_review_student_context` shows the model the student's **still-valid
contexts, numbered**, their goals, their recent lesson answers and their recent
chats, and asks two things back:

- `reviewed` — one entry per context shown: its index and whether it is now
  outdated;
- `new_contexts` — readings to add, each a `state` and a `metacognition`;
- `frontiers` — the goals whose frontier the student has outgrown, each the
  goal's index in the prompt and the new definition (#133).

**Both lists empty is a valid, normal, cheap answer** meaning nothing changed,
and the step then writes nothing. An outdated context is **retired**
(`is_still_valid = false`), never deleted: it is progression history the
student is meant to be able to read. An index the model invented, or repeated,
is **dropped, not an error** — the same tolerance the question bank has for a
correct-option index out of range.

The first-impression path is unchanged: a student with no standing context, or
no lesson answered, is introduced rather than reviewed.

### The goal is where he started; the frontier is where we take him (#133)

A goal names what the student wanted to learn **about**, not a course with a
finish line. `goals.description` is what he asked for on day one and never
changes; **`frontiers`** (`id`, `goal_id`, `definition`, `definition_embedding`,
`created_at`) is where the app is taking him now.

- **Append-only**, like `student_contexts`. The current frontier is the goal's
  newest row; the rows before it are the record of where he has been taken.
  Nothing is edited or deleted.
- **The first frontier exists from creation.** `GoalRepository.create` writes it
  with the goal, from the description the student approved, so no reader ever
  handles "no frontier yet".
- **The move rides on the context review**, because that call already reads the
  goals, the recent answers and the recent tutor chats — and what he asks the
  tutor is the evidence of what he is interested in. **A night that moves
  nothing writes no row**, which is the normal night.
- **A proposal far from the goal's own embedding is refused and logged.** The
  move must stay recognisable as the same goal seen further on; the row is the
  one thing that cannot be taken back. Where the comparison cannot be made — no
  goal embedding yet, or Gemini will not answer — the move is written and logged
  as unchecked: nothing here is ever blocked by a missing embedding.
- **Question generation aims at the frontier**, with the day-one description in
  the prompt as background.
- Nothing is stored about what a generation aimed at: the frontier in force when
  a question was written is the newest one dated before that question.

### When questions are generated (#91)

Before generating, the step counts what tomorrow can be built from — the
**selection rule** above: questions whose latest answer was **wrong**, plus
questions **never answered**. Call that the servable bank.

- servable ≥ `QUESTIONS_PER_LESSON` (8) ⇒ **generate nothing**. That is the student
  who is struggling, and struggling makes the job cheaper: a question stays in
  rotation until it is answered right, so there is no reason to buy new ones to
  sit behind it.
- otherwise ask Gemini for `2 × QUESTIONS_PER_LESSON − servable`
  (`TARGET_SERVABLE` = 16). One lesson of that is tomorrow's gap; the second is the
  **margin**, and it is one lesson because a student who answers tomorrow's
  questions correctly consumes all of them — without it the bank is short again
  the very next night, and that night is the one that may find Gemini down.
  One lesson of margin buys exactly one missed night.

`generate_lesson_questions(..., count)` takes how many to ask for, because the
number is different every night. Counted **per goal**: a deep bank in law says
nothing about tomorrow's history lesson.

**Superseded scheduling rule for memories** (the user's earlier intent, never
implemented): check every student **daily**, but only regenerate if **≥3 days
since the last generation** AND the student actually chatted or did a lesson in
between. #90 replaced the three-day rule: the gate is the day's lesson (#89), and
Gemini itself says what is stale.

**History — the old nightly schedule (deleted 2026-09-21).** `backend/core/scheduler.py`
wired four APScheduler daily crons: lesson creation (04:30), lesson context
(02:00), chat context (03:00), mastery evaluation (05:00). All four job modules
had already been deleted in Major/refactor (#41), so every import was broken; the
file has now been removed too. Kept here as design history — note it split memory
generation into **two** jobs (chats and lessons separately) and had a
**mastery evaluation** job the current plan does not mention.

**Decided: collapse to two nightly jobs.** One updates context/memories, one
creates lessons — in that order, because lesson creation consumes the memories.
Four jobs was over-splitting. That became the chain above, with resources as its
third step, and the `nightly` service is what runs it.

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
answers, one revises it from recent lesson results and chat history. The chain's
first step picks between them by what it finds (#88). `is_still_valid` retires a stale context **without
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
                          "recent_lessons": [ recent_lesson ] }   // newest first
recent_lesson           { "lesson_id": "...", "date": "2026-06-06", "accuracy": 90.0,
                          "duration_seconds": 137 }   // the answers sharing one mark

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
  (`GoalRepository.add_to_rating`, #72). Where that change went is **not**
  recorded anywhere: the column that held it went with the `lessons` table
  (#131), and the rating gets a history again with #62.
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
