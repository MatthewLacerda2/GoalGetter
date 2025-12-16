# GoalGetter

An educational app with an AI-Tutor

## How it works

- Goal
  At the onboarding the user states what he wants to learn, and answers some follow-up questions
- Lessons
  Multiple Choice questions with didatic purpose
  Subjective questions to stimulate thinking
  Subjective questions aiming at assessing the student's knowledge
- Objective
  The next immediate step towards the goal
  Once the student shows they dominate the objective, we create a new one
- Tutoring
  A chatbot

We also have a 'Resources' tab with material recommendations (ebooks, websites and youtube)

The lessons are generated when we are low in questions for the user. That includes:

- When the onboarding finishes
- When a new subject is created
- Periodically, at a cron job, for users whom we see might need more questions soon

## Philosophy

- Goal
  Must be the most ambitious possible
- Small steps
  Each objective is the smallest step possible above the student's current level
- Gamification
  We have XP and Streaks, aimed at user-retention
- 1:1 Tutoring
  We record data and context all the time. That is used to create a custom-tailored experience

## Tech Stack and Infrastructure

Flutter: - Webapp and Android
FastApi: - Api. Users can login, use the AI and save their goals
Client_SDK: - Generated with the OpenAPI.json from the backend - Flutter sees it as a dart package. It must must have it's own root folder
Pytest: - Tests for the api
Terraform: - Infra-as-code
Ansible: - Automate server setup

We'll use Cloudflare Tunnel. Gemini and Ollama will be our content creators and chatbots

We use Google Gemini 2.5

## How to run

### Production Deployment (Arch Linux Home Server)

For home deployment on Arch Linux, you'll use:

- Docker Compose for backend and databases
- Host nginx (systemd service) for reverse proxy with SSL

1. Copy `example.env` to `.env` and fill in your values:

   ```bash
   cp example.env .env
   ```

2. Build the frontend:

   ```bash
   cd frontend
   flutter build web --release
   cd ..
   ```

3. Update `nginx.conf`:

   - Set `root` path to your frontend build: `/path/to/GoalGetter/frontend/build/web`
   - Set SSL certificate paths: `/etc/nginx/ssl/server.crt` and `/etc/nginx/ssl/server.key`

4. Start Docker services:

   ```bash
   docker-compose -f docker-compose.prod.yml up -d
   ```

5. Copy nginx config and start nginx service:

   ```bash
   sudo cp nginx.conf /etc/nginx/nginx.conf
   sudo systemctl enable nginx
   sudo systemctl start nginx
   ```

6. Run tests:

   ```bash
   docker-compose -f docker-compose.prod.yml exec backend pytest tests/ -v
   ```

### Development (Docker Compose)

1. Copy `example.env` to `.env` and fill in your values:

   ```bash
   cp example.env .env
   ```

2. Start all services:

   ```bash
   docker-compose up -d
   ```

   This will start:

   - PostgreSQL (production) on port 5432
   - PostgreSQL (test) on port 5433
   - Backend FastAPI on port 8001 (with hot-reload)
   - Frontend Flutter web on port 80 (via nginx in container)

3. View logs:
   ```bash
   docker-compose logs -f
   ```

### Manual Setup

- uvicorn backend.main:app --host 127.0.0.1 --port 8001 --reload
- - Get the openapi.json from swagger-ui \*
- openapi-generator-cli generate -i ./openapi.json -g dart -o ./client_sdk

Development:

- flutter run -d chrome --web-port=8080
  Production:
- Build it with `flutter build web`
- From ./frontend/build/web: `python -m http.server`

Chrome is just for development purposes. The app is meant to be used on mobile only

## Conventions

All Schemas sent to Gemini have 'Gemini' as prefix and do not have pydantic's Field annotators

---

we need to make the triggers, for when subscribing we generate the user's lessons ASAP
and the frontend exhibits nothing while we dont have anything
