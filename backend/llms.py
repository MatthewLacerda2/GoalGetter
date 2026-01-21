"""LLMs.txt content - AI version of robots.txt for GoalGetter."""

def get_llms_txt() -> str:
    """Returns the llms.txt content as a markdown string."""
    return """# GoalGetter

An educational app with an AI tutor.

## How it works

- **Goal**: During onboarding, the user states what they want to learn and answers follow-up questions.
- **Objective**: The next immediate step toward the goal. Once the student shows they master the objective, we create a new one.
- **Lessons**:
  - Multiple-choice questions with a didactic purpose
  - Subjective questions to stimulate thinking
  - Subjective questions to assess the student's knowledge
- **Tutoring**: A chatbot with knowledge about the user.
- **Gamification**:
  - Leaderboards
  - Missions
  - Achievements
- **Resources**: Recommendations of websites, YouTube channels, and eBooks.

All content is custom-tailored for the user. It's a 1:1 tutor app!

## Philosophy

- **Goal**: Must be as ambitious as possible.
- **Small steps**: Each objective is the smallest step possible above the student's current level.
- **Gamification**: We have XP and streaks aimed at user retention.
- **1:1 Tutoring**: We record data and context all the time; that is used to create a custom-tailored experience.
"""
