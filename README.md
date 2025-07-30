# GoalGetter

An app to help plan a weekly-routine with long term goals
It also helps planning a roadmap for achieving a goal

# How it works

- Goals: define what you want to do
- Agenda: setup your weekly schedule
    Look what you have for the day of the week
    Keep consistent in your goals
- Xp: get reminded and rewarded for progress (a lá Duolingo)
    Look how consistent you've been
    Get encouraged to continue
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