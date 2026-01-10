"""LLMs.txt content - AI version of robots.txt for GoalGetter."""

def get_llms_txt() -> str:
    """Returns the llms.txt content as a markdown string."""
    return """# GoalGetter
An educational app with an AI-Tutor

## How it works

- Goal
  At the onboarding the user states what he wants to learn, and answers some follow-up questions
- Objective
  The next immediate step towards the goal
  Once the student shows they dominate the objective, we create a new one
- Lessons
  Multiple Choice questions with didatic purpose
  Subjective questions to stimulate thinking
  Subjective questions aiming at assessing the student's knowledge
- Tutoring
  A chatbot with knowledge about the user
- Gamefication
  Leaderboards
  Missions
  Achievments
- Resources
  Recommendations of Websites, Youtube Channels and eBooks
  
All content is custom-tailored for the user. It's a 1:1 Tutor App!

## Philosophy

- Goal
  Must be the most ambitious possible
- Small steps
  Each objective is the smallest step possible above the student's current level
- Gamification
  We have XP and Streaks, aimed at user-retention
- 1:1 Tutoring
  We record data and context all the time. That is used to create a custom-tailored experience
"""
