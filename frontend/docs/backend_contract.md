# Backend endpoints (derived from the frontend mocks)

> Status: **target for backend work** — the new-version backend does not exist
> yet. The Flutter frontend runs entirely on mock fixtures
> (`features/**/debug/mock_*.dart`); this document is the contract those mocks
> imply, so the FastAPI backend can be built to match and the Dart client
> regenerated from it (see `api_codegen_flow.md`).

**Conventions**

- All paths assume the `/api/v1` prefix (e.g. `GET /me` = `GET /api/v1/me`).
- All endpoints require `Authorization: Bearer <accessToken>` **except**
  `POST /auth/signup`, which carries the Google token.
- Error responses (`401`, `403`, `404`) are intentionally **omitted** below —
  only success shapes are listed.
- Times are ISO-8601 strings. Field names are the frontend's expectation
  (camelCase); the backend may use snake_case and let the generator map them.
- Demo data models one user, **"Marco"**, **7 days** into the app, learning
  **Italian**, with a **7-day streak**. All mocks are mutually consistent.

Shared object shapes are defined once in [Schemas](#schemas) and referenced by
name below.

---

## Auth

### `POST /auth/signup`
Sign up or log in with a Google token (creates the account if new). Returns the
app session.
- **Params:** none
- **Request:** header `Authorization: Bearer <googleToken>`; no body
- **Response `200`:**
  ```jsonc
  {
    "accessToken": "jwt…",
    "student": { "id": "user_marco", "name": "Marco Rossi", "email": "marco.rossi@example.com" }
  }
  ```
- _Mock:_ `auth_service.signupWithGoogle`

---

## User

### `GET /me`
The signed-in user's profile. Drives startup routing and the Profile header.
- **Params:** none
- **Request:** none
- **Response `200`:** [`UserProfile`](#userprofile)
- _Mock:_ `mock_profile.dart`

---

## Goals

### `GET /goals`
All of the user's goals. Exactly one has `isActive: true` (drives Home).
- **Params:** none
- **Request:** none
- **Response `200`:** [`Goal`](#goal)`[]`
- _Mock:_ `mock_goals.dart`

### `POST /goals/objective-questions`
Step 1 of goal creation: given the user's free-text prompt, return clarifying
multiple-choice questions (currently 6).
- **Params:** none
- **Request:**
  ```jsonc
  { "prompt": "I want to learn Italian for a trip to Rome" }
  ```
- **Response `200`:**
  ```jsonc
  { "questions": [
    { "questionText": "What is your primary learning goal?",
      "options": ["Career advancement", "Personal interest", "School project", "Building a product"] }
  ] }
  ```
- _Mock:_ `mock_goal_prompt_screen.dart` (`fetchMockObjectiveQuestions`)

### `POST /goals/study-plan`
Step 2: given the prompt + the answers to the objective questions, return a
short, AI-generated study plan to confirm.
- **Params:** none
- **Request:**
  ```jsonc
  { "prompt": "I want to learn Italian…",
    "answers": ["Personal interest", "Absolute beginner", "15 to 30 minutes", "…"] }
  ```
- **Response `200`:**
  ```jsonc
  { "goalName": "Learn Italian",
    "description": "To reach this goal… - Build a **daily practice** habit…" }
  ```
  `description` is short markdown.
- _Mock:_ `mock_goal_questions_screen.dart` (`generateMockStudyPlan`)

### `POST /goals`
Step 3: create the goal from the accepted plan. The new goal becomes the active
one.
- **Params:** none
- **Request:**
  ```jsonc
  { "prompt": "I want to learn Italian…",
    "answers": ["…"],
    "studyPlan": { "goalName": "Learn Italian", "description": "…" } }
  ```
- **Response `200`:** [`Goal`](#goal) (the created goal, `isActive: true`)
- _Mock:_ `mock_study_plan.dart` (`submitMockFullCreation`)

### `PUT /goals/{goalId}/set-active`
Make the given goal the active one (the only place the active goal is switched).
- **Params:** path `goalId`
- **Request:** none
- **Response `200`:** `{ "goalId": "goal_italian" }`
- _Mock:_ goals detail screen (mocked locally)

### `DELETE /goals/{goalId}`
Delete a goal and its data.
- **Params:** path `goalId`
- **Request:** none
- **Response `204`:** no body
- _Mock:_ goals detail screen (mocked locally)

---

## Home

### `GET /goals/{goalId}/dashboard`
Everything the Home dashboard needs for one goal: current rating, the recent
lessons list, and the elo-over-time history.
- **Params:** path `goalId`
- **Request:** none
- **Response `200`:**
  ```jsonc
  {
    "goalName": "Learn Italian",
    "currentElo": 920,
    "recentLessons": [
      // most-recent first
      { "date": "2026-06-06", "accuracy": 90.0, "eloDelta": 10, "durationSeconds": 137 }
    ],
    "eloHistory": [
      // one point per day, oldest first; client filters to 7/30/90 days
      { "date": "2026-05-31", "elo": 854 }
    ]
  }
  ```
  Once lessons are persisted, each `recentLessons[*]` should also carry a
  `lessonId`.
- _Mock:_ `mock_home_screen.dart`

---

## Lessons

### `POST /goals/{goalId}/lessons`
Start a lesson for the active goal — returns a fresh set of multiple-choice
questions (currently 5).
- **Params:** path `goalId`
- **Request:** none
- **Response `200`:**
  ```jsonc
  { "lessonId": "lesson_123",
    "questions": [ /* MultipleChoiceQuestion */ ] }
  ```
  See [`MultipleChoiceQuestion`](#multiplechoicequestion). `correctAnswerIndex`
  may instead be withheld and returned only on evaluation, if you want
  server-side grading.
- _Mock:_ `mock_lesson_controller.dart` (`getMockLessonQuestions`)

### `POST /goals/{goalId}/lessons/{lessonId}/evaluate`
Submit the student's answers; returns the lesson result. Side effects: updates
the goal's elo and the user's streak.
- **Params:** path `goalId`, `lessonId`
- **Request:**
  ```jsonc
  { "answers": [
    { "questionId": "q1", "choiceIndex": 0, "secondsSpent": 12 }
  ] }
  ```
- **Response `200`:** [`LessonEvaluation`](#lessonevaluation)
- _Mock:_ computed client-side in `lesson_controller.dart` via `mockEloForAccuracy`

---

## Streak

### `GET /streak`
The user's current-week streak (user-wide, not per goal).
- **Params:** none
- **Request:** none
- **Response `200`:** [`Streak`](#streak)
- _Mock:_ `mock_streak_screen.dart`

---

## Resources

### `GET /resources`
Curated learning resources for a goal, grouped by kind.
- **Params:** query `goalId`
- **Request:** none
- **Response `200`:**
  ```jsonc
  {
    "youtube": [ /* ResourceItem (with image) */ ],
    "sites":   [ /* ResourceItem (with image) */ ],
    "books":   [ /* ResourceItem (no image) */ ]
  }
  ```
  See [`ResourceItem`](#resourceitem). (A flat `ResourceItem[]` with a `type`
  field would also work.)
- _Mock:_ `mock_resources_screen.dart`

---

## Tutor (chat)

### `GET /tutor/messages`
Chat history with the AI tutor, paginated (oldest→newest within a page; load
older on scroll-up).
- **Params:** query `goalId`, `cursor` (optional)
- **Request:** none
- **Response `200`:** [`ChatMessage`](#chatmessage)`[]`
- _Mock:_ `mock_tutor_controller.dart` (`getMockChatMessages`)

### `POST /tutor/messages`
Send a user message; returns the tutor's reply.
- **Params:** none
- **Request:**
  ```jsonc
  { "goalId": "goal_italian", "message": "When do I use essere vs avere?" }
  ```
- **Response `200`:** [`ChatMessage`](#chatmessage) (the tutor's reply)
- _Mock:_ `mock_tutor_controller.dart` (`getMockTutorResponse`)

### `POST /tutor/messages/{messageId}/like`
Toggle the "liked" state on a tutor message.
- **Params:** path `messageId`
- **Request:** `{ "isLiked": true }`
- **Response `200`:** no body (or the updated [`ChatMessage`](#chatmessage))
- _Mock:_ `tutor_controller.toggleLikeMessage` (local only)

---

## Schemas

### UserProfile
```jsonc
{ "id": "user_marco", "name": "Marco Rossi", "email": "marco.rossi@example.com",
  "memberSince": "2026-05-31T00:00:00Z", "currentStreak": 7 }
```

### Goal
```jsonc
{ "id": "goal_italian", "name": "Learn Italian", "description": "Reach conversational fluency…",
  "createdAt": "2026-05-31T00:00:00Z", "currentElo": 920, "isActive": true }
```

### MultipleChoiceQuestion
```jsonc
{ "id": "q1", "question": "How do you say \"hello\" in Italian?",
  "choices": ["Ciao", "Hola", "Bonjour", "Hallo"], "correctAnswerIndex": 0 }
```

### LessonEvaluation
```jsonc
{ "totalSecondsSpent": 142, "studentAccuracy": 80.0, "elo": 14 }
```
`elo` is the signed rating change for this lesson (renamed from the old `xp`).

### Streak
```jsonc
{ "currentStreak": 7,
  "week": { "monday": true, "tuesday": true, "wednesday": true, "thursday": true,
            "friday": true, "saturday": true, "sunday": true } }
```
Each day is tri-state: `true` completed, `false` missed, `null` not-yet (future
days this week).

### ResourceItem
```jsonc
{ "title": "Learn Italian with Lucrezia",
  "description": "Native-speaker lessons on everyday Italian…",
  "link": "https://youtube.com/…",
  "image": "https://… (optional — present for videos/sites, absent for books)" }
```

### ChatMessage
```jsonc
{ "id": "msg_1", "message": "Ciao Marco! …", "sender": "tutor", "isLiked": false }
```
`sender` ∈ {`user`, `tutor`}. The backend may instead return `senderId` and let
the client resolve it against the current user id.

---

## Notes for implementers
- Use **elo** everywhere (the old SDK used `xp`).
- Anything deep-linkable (e.g. `/goals/{id}`) must be fetchable by id — rich
  objects passed via go_router `extra` aren't restored on web refresh.
- After endpoints land, regenerate the Dart client and replace the `mock_*.dart`
  fixtures + domain models with generated calls, feature by feature. The thin
  `*_controller.dart` providers are the swap point.
