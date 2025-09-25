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

## Philosophy

- Goal
    Must be the most ambitious possible
- Small steps
    Each objective is the smallest step possible above the student's current level
- Gamification
    We have XP and Streaks, aimed at user-retention
- 1:1 Tutoring
    We record data and context all the time. That is used to create a custom-tailored experience

## Tech Stack

Flutter:
    - Webapp and Android
FastApi:
    - Api. Users can login, use the AI and save their goals
Client_SDK:
    - Generated with the OpenAPI.json from the backend
    - Flutter sees it as a dart package. It must must have it's own root folder
Pytest:
    - Tests for the api
Terraform:
    - Infra-as-code

We use Google Gemini 2.5

## How to run

- uvicorn backend.main:app --webhost <your-ip> --reload
- * Get the openapi.json from swagger-ui *
- openapi-generator-cli generate -i ./openapi.json -g dart -o ./client_sdk
- flutter run -d chrome --web-host=<your-ip> --web-port=8080

Chrome is just for development purposes. The app is meant to be used on mobile only

## Conventions

All Schemas sent to Gemini have 'Gemini' as prefix and do not have pydantic's Field annotator