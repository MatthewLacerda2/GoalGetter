# GoalGetter

An educational app with a custom-tailored AI-Tutor designed to help people learn anything, frictionlessly.

## The Mission & Motivation
What makes this app viable is the use of AI to generate custom-tailored lessons, explanations, and resources specifically targeted to each student's current needs and progress.

---

## How It Works

- **Micro-Lessons**: Users do at least one lesson a day. Each lesson has a series of multiple-choice questions. At the end the user receives XP and guarantees the daily streak. Inspired by Duolingo.
- **Microlearning Content**:
  Small, easy-to-read, non-technical text for the user to quickly learn a small bit of knowledge.
- **Daily Streak Mechanic**:
  To encourage daily consistency, users earn a daily streak. The streak is tied to the *user*, not a specific goal—meaning you can study Goal X today and Goal Y tomorrow to maintain a 2-day consecutive streak.
- **Off-the-Hook Days**:
  To prevent burnout and avoid discouraging users who miss a day, the app lets you "off the hook" up to two days per week without breaking your streak.
- **Chess-like Rating System**:
  Each goal tracks a user's `rating` (similar to a chess rating). As the user answers questions correctly, their rating increases. The AI generates and presents questions suited for someone at that rating level, serving as a reflection of their actual experience in the subject and motivating them to progress.
- **Resources Screen**:
  Curated suggestions of YouTube channels/videos, PDF guides, and external websites matching the active goals.
- **Multi-Goal Tracking**:
  Users can define and pursue multiple goals at the same time.

---

## Core Principles

* **Frictionless Experience**: Users must have a seamless, zero-friction flow between launching the app and finishing their daily lesson.
* **Effective Learning**: Users must feel a genuine sense of comprehension and progress.
* **Mastery Focus**: The app holds an ambitious goal of guiding the student to fully master the subject matter.
* **High Retention**: We MUST convince the user to come back every day.

---

## Infra and Tech Stack

* **Frontend**: [Flutter](https://flutter.dev/) (currently web-app, intended to transition fully to mobile)
* **Backend**: [FastAPI](https://fastapi.tiangolo.com/) with [SQLAlchemy](https://www.sqlalchemy.org/)
* **Testing**: [pytest](https://docs.pytest.org/) for backend test suites
* **Database**: PostgreSQL with [pgvector](https://github.com/pgvector/pgvector) for storing vector embeddings
* **AI engine**: Google Gemini (integrated via Gemini SDK)
* **Hosting / Delivery**: Home-deployed, serving traffic securely using a Cloudflare Tunnel

---

# How to Run

You will need a Gemini API Key. You can obtain one on the free tier at [Google AI Studio](https://aistudio.google.com/api-keys).

1. Copy `.env.example` to `.env` and fill in your Gemini API key and database credentials.
2. Spin up the environment using Docker Compose:
   ```bash
   docker compose up -d
   ```
3. Create a Python virtual environment and run database migrations:
   ```bash
   # Create and activate venv (Python 3.12 recommended)
   python -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   
   # Run migrations (ensure DB is up)
   alembic upgrade head
   ```
4. Start the backend development server:
   ```bash
   uvicorn backend.main:app --reload
   ```
5. Run the frontend (web app):
   ```bash
   cd frontend
   flutter run -d chrome --web-port=8080
   ```

To generate the OpenAPI schema and rebuild the Dart client SDK, run the helper script:
```bash
./generate_sdk.sh
```

The system was made with Linux as the OS for development and deployment.
