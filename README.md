# GoalGetter

An app to help plan a weekly-routine with long term goals

# How it works

- Agenda: setup your weekly schedule
    Look what you have for the day of the week
- Tasks: how you spent your weekly time
    Check out what you have for the day
    Create tasks for your goals
- Goals: to your road
    Easily have a thought-out roadmap
    Look your list of tasks
    Get warned when you didn't assign enough time
- Motivation: pushy!
    We make sure you keep motivated
    Let us handle the thinking plan
- Profile: user settings
    Get personal

# Infra

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

- Frontend: flutter run -d chrome --web-host <your-ip> --port 8080
- Backend: uvicorn backend.main:app --webhost <your-ip> --reload

The .env needs: google_gemini_api_key, backend_url