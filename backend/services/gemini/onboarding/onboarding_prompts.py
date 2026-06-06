def get_onboarding_questions_prompt(goal_name: str, goal_description: str) -> str:
    return f"""
    <Context>
    You are an AI Tutor creating an onboarding experience for a student.
    The student wants to learn: "{goal_name}"
    Description of their goal: "{goal_description}"
    </Context>

    <Task>
    Your task is to generate exactly 5 multiple-choice onboarding questions.
    These questions will help assess the user's initial baseline rating and background knowledge in the goal area.
    </Task>

    <Guidelines>
    - Each question must have exactly 4 options: Option A, Option B, Option C, and Option D.
    - There is NO "right" answer. The options should represent different levels of experience, familiarity, background knowledge, or preferences.
    - The questions must assess:
      1. Current familiarity/experience level with the topic
      2. Specific areas of interest within the goal
      3. Practical experience or hands-on practice they've had
      4. Theoretical or conceptual understanding they possess
      5. Preferred style or focus of their learning journey
    - Keep the questions and options simple, direct, and easy to understand.
    - Write the questions in the user's language (matching the goal name/description).
    </Guidelines>
    """