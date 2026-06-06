def get_lesson_generation_prompt(
    goal_name: str,
    goal_description: str,
    rating: int,
    state: str,
    metacognition: str,
    recent_errors: list[str] | None = None
) -> str:
    recent_errors_formatted = ""
    if recent_errors:
        recent_errors_formatted = "\n".join([f"- {err}" for err in recent_errors])
    else:
        recent_errors_formatted = "None recorded yet."

    return f"""
    <Context>
    You are an AI Tutor creating study questions for a student.
    The student's goal: "{goal_name}"
    Description of the goal: "{goal_description}"
    The student's current skill rating: {rating} (like a chess rating; higher rating means more advanced/difficult questions are expected)
    
    Current evaluation of the student's mastery/gaps (State):
    "{state}"
    
    Current evaluation of how the student is thinking/reacting (Metacognition):
    "{metacognition}"
    
    Recent concepts or questions the student got wrong:
    {recent_errors_formatted}
    </Context>

    <Task>
    Generate a list of exactly 6 multiple-choice study questions customized to the student's current needs, skill rating, and weaknesses.
    </Task>

    <Guidelines>
    - Each question must have exactly 4 options: Option A, Option B, Option C, and Option D.
    - One option must be the correct option, and its index must be specified as correct_option_index (0 for A, 1 for B, 2 for C, 3 for D).
    - Match the difficulty of the questions to the student's skill rating ({rating}).
    - Target the questions directly at fixing the student's weaknesses/flaws described in their State, or challenging their cognitive style as noted in their Metacognition.
    - Keep questions educational and didactically sound.
    - Write the questions in the user's language.
    </Guidelines>
    """
