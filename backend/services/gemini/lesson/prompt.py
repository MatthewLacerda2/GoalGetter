from backend.services.gemini.student_context.schema import GeminiStudentContext
from backend.utils.envs import QUESTIONS_PER_LESSON


def format_contexts(contexts: list[GeminiStudentContext]) -> str:
    """The student's still-valid contexts, newest first. They are written about
    the person and not about this goal (#87), so several may apply at once."""
    if not contexts:
        return "No reading of this student has been written yet."
    return "\n".join(
        [f'- State: "{c.state}" - Metacognition: "{c.metacognition}"' for c in contexts]
    )


def get_lesson_generation_prompt(
    goal_name: str,
    goal_description: str,
    frontier: str,
    rating: int,
    contexts: list[GeminiStudentContext],
    recent_errors: list[str] | None = None,
    count: int = QUESTIONS_PER_LESSON,
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
    What he asked for on day one: "{goal_description}"
    **What to teach him now - his current frontier: "{frontier}"**
    The student's current skill rating: {rating} (like a chess rating; higher rating means more advanced/difficult questions are expected)

    What the app knows about this learner - their mastery and gaps (State), and
    how they think and react (Metacognition). It is written about the person,
    so it covers everything they study, not only this goal:
    {format_contexts(contexts)}

    Recent concepts or questions the student got wrong:
    {recent_errors_formatted}
    </Context>

    <Task>
    Generate a list of exactly {count} multiple-choice study questions customized to the student's current needs, skill rating, and weaknesses.
    </Task>

    <Guidelines>
    - Each question must have exactly 4 options: Option A, Option B, Option C, and Option D.
    - One option must be the correct option, and its index must be specified as correct_option_index (0 for A, 1 for B, 2 for C, 3 for D).
    - Match the difficulty of the questions to the student's skill rating ({rating}).
    - Target the questions directly at fixing the student's weaknesses/flaws described in their State, or challenging their cognitive style as noted in their Metacognition.
    - **Ask about the frontier.** The day-one description is background: it
      says where the student came from, not what to ask him about. A goal has
      no finish line, and the frontier is where he has been taken since.
    - The questions are about this goal only. The student's context may mention other subjects they study; use it to judge how they learn, never as a topic to ask about.
    - Keep questions educational and didactically sound.
    - Write the questions in the user's language.
    </Guidelines>
    """
