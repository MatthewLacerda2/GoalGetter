"""LLMs.txt content - AI version of robots.txt for GoalGetter."""

def get_llms_txt() -> str:
    """Returns the llms.txt content as a markdown string."""
    return """# GoalGetter

An educational app with a custom-tailored AI-Tutor designed to help people learn anything, frictionlessly.

## How it works

- **Multi-Goal Tracking**: Users can define and pursue multiple goals at the same time.
- **Micro-Lessons**: Quick 2-3 minute daily lessons consisting of multiple-choice questions. Incorrect answers are repeated until mastered. Completion percentage and XP are awarded.
- **Chess-like Rating System**: Each goal tracks a user's `rating` representing their mastery. The AI generates and presents questions suited for the student's current rating level.
- **AI Tutoring**: A chatbot with deep, personalized context about the student's progress and onboarding profile.
- **Daily Streak & Off-the-Hook Days**: A streak mechanic tied to the user (not a specific goal). Users are allowed up to two "off the hook" days per week to prevent burnout.
- **Resources Recommendations**: Curated suggestions of YouTube channels/videos, PDF guides, and external websites matching active goals.

All content is custom-tailored for the user. It's a frictionless, 1:1 tutor app!

## Core Principles

- **Frictionless Experience**: Seamless flow between launching the app and starting/finishing lessons.
- **Effective Learning**: A genuine sense of comprehension and progress.
- **Mastery Focus**: Guiding the student to fully master the subject matter.
- **Chess-like Rating**: Adapting question difficulty to the student's rating for optimal challenge (not too easy, not too hard).
- **1:1 Tutoring**: We record student context and onboarding data to dynamically customize lessons and resources.
"""

