# GoalGetter

An educational app with an AI-Tutor

# How it works

- Goal
- Lessons
- Progress
- Tutoring

# Philosophy

- Goal
- Small steps
- Gamification
- 1:1 Tutoring

# Tech Stack

Flutter:
    - Webapp and Android
FastApi:
    - Api. Users can login, use the AI and save their goals
Pytest:
    - Tests for the api
Client_SDK:
    - OpenAPI generated client_sdk for the frontend
    - Dart sees it as a dart package that must have it's own folder outside of the frontend's
Terraform:
    - Infra-as-code

We use Google Gemini as our AI

# How to run

To generate the client_sdk: openapi-generator-cli generate -i ./openapi.json -g dart -o ./client_sdk

- Backend: uvicorn backend.main:app --webhost <your-ip> --reload
- Frontend: flutter run -d chrome --web-host=<your-ip> --web-port=8080