# Backend Contract (derived from frontend mocks)

> Status: **target for backend work** — the new-version backend does not exist
> yet. The Flutter frontend currently runs entirely on mock fixtures
> (`features/**/debug/mock_*.dart`). This document lists the endpoints and
> schemas those mocks imply, so backend (FastAPI + SQLAlchemy + the regenerated
> Dart client SDK) can be built to match. Field names are the frontend's
> expectation; adjust together when implementing.
>
> Auth/paths are illustrative (`/api/v1` prefix assumed). Times are ISO-8601.
> The legacy `client_sdk` is deprecated — do NOT treat it as the source of truth.

Demo data models a single user, **"Marco"**, **7 days** into the app, learning
**Italian**, with a **7-day streak**. All mocks are mutually consistent.

---

## Auth / startup
Frontend: `app/startup/app_start_controller.dart` (currently mocked to
`authenticatedReady`).

- `GET /me` → **UserProfile**
  ```jsonc
  { "id": "user_marco", "name": "Marco Rossi", "email": "marco.rossi@example.com",
    "memberSince": "2026-05-31T00:00:00Z", "currentStreak": 7 }
  ```
  Drives: startup routing (has session?), Profile header. Streak is user-wide.

## Goals
Frontend: `features/goals/` (`Goal` model, `mock_goals.dart`).

- `GET /goals` → **Goal[]**
  ```jsonc
  { "id": "goal_italian", "name": "Learn Italian", "description": "…",
    "createdAt": "2026-05-31T00:00:00Z", "currentElo": 920, "isActive": true }
  ```
- `PUT /goals/{id}/set-active` → `{ "goalId": "goal_italian" }`
- `DELETE /goals/{id}` → 204
- Onboarding goal creation (already has SDK shapes, keep): follow-up questions,
  study plan, full creation.

## Home dashboard
Frontend: `features/home/` (`mock_home_screen.dart`). Scoped to the **active goal**.

- `GET /goals/{id}/dashboard` (or `GET /home`) → **HomeDashboard**
  ```jsonc
  {
    "goalName": "Learn Italian",
    "currentElo": 920,
    "recentLessons": [
      { "date": "2026-06-06", "accuracy": 90.0, "eloDelta": 10 }
      // … most-recent first
    ],
    "eloHistory": [
      { "date": "2026-05-31", "elo": 854 }
      // … one point per day, oldest first; client filters to 7/30/90 days
    ]
  }
  ```
  Note: `eloHistory` granularity = one point per day. `recentLessons[*]` should
  also carry a `lessonId` once lessons are persisted.

## Streak
Frontend: `features/lessons/debug/mock_streak_screen.dart`.

- `GET /streak` → **Streak**
  ```jsonc
  { "currentStreak": 7,
    "week": { "monday": true, "tuesday": true, "wednesday": true,
              "thursday": true, "friday": true, "saturday": true, "sunday": true } }
  ```
  Per-day value is tri-state: completed / missed / not-yet (null for future days).
  Add `offHookDaysRemaining` (README: up to 2/week) when implementing.

## Lessons / activities
Frontend: `features/lessons/` (`lesson_models.dart`, `mock_lesson_controller.dart`).

- `POST /activities` (take a multiple-choice activity for the active goal) →
  **{ questions: MultipleChoiceQuestion[] }**
  ```jsonc
  { "id": "q1", "question": "How do you say \"hello\" in Italian?",
    "choices": ["Ciao", "Hola", "Bonjour", "Hallo"], "correctAnswerIndex": 0 }
  ```
  (correctAnswerIndex may stay server-side and be returned only on evaluation.)
- `POST /activities/evaluate` with the student's answers → **LessonEvaluation**
  ```jsonc
  { "totalSecondsSpent": 142, "studentAccuracy": 80.0, "elo": 14 }
  ```
  `elo` is the signed rating change for this lesson (renamed from the old `xp`).

## Tutor (chat)
Frontend: `features/tutor/` (`chat_message.dart`, `mock_tutor_controller.dart`).

- `GET /tutor/messages?goalId=&cursor=` → **ChatMessage[]** (paginated, newest last)
  ```jsonc
  { "id": "msg_1", "message": "Ciao Marco! …", "sender": "tutor",
    "isLiked": false, "createdAt": "2026-06-06T09:00:00Z" }
  ```
  `sender` ∈ {`user`, `tutor`} (backend may instead send `senderId` + the
  caller resolves against the current user id).
- `POST /tutor/messages` `{ "message": "…" }` → the tutor's reply **ChatMessage**.
- `POST /tutor/messages/{id}/like` `{ "isLiked": true }` → 200.

## Resources
Frontend: `features/resources/` (`mock_resources_screen.dart`).

- `GET /resources?goalId=` → **{ youtube: ResourceItem[], sites: ResourceItem[], books: ResourceItem[] }**
  ```jsonc
  { "title": "Learn Italian with Lucrezia", "description": "…",
    "link": "https://…", "image": "https://… (optional)" }
  ```
  Consider a flat `ResourceItem[]` with a `type` field instead of three keys.

---

## Notes for implementers
- Switch terminology to **elo** everywhere (the old SDK used `xp`).
- Rich objects passed via go_router `extra` (goal, study plan) aren't restored on
  web refresh — anything deep-linkable (e.g. `/goals/{id}`) should be fetchable
  by id.
- After endpoints land, regenerate the Dart SDK and replace the `mock_*.dart`
  fixtures + frontend domain models with SDK-backed calls, controller by
  controller.
