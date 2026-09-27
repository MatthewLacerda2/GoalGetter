from backend.core.config import settings
from backend.core.language import Language
from backend.services.gemini.lesson.prompt import EXERCISE_RULES, LEVEL_RULES, format_contexts
from backend.services.gemini.student_context.schema import GeminiStudentContext


def get_placement_prompt(
    goal_name: str,
    asked: str,
    contexts: list[GeminiStudentContext],
    language: Language,
) -> str:
    return f"""
    You write the first exercises of a student who just started a new subject.
    What he asked to learn, in his own words: "{asked}"
    (The app titled it "{goal_name}"; his words above are what counts.)

    What the app has read about him so far (his own words, not a measurement):
    {format_contexts(contexts)}

    Write exactly {settings.PLACEMENT_SIZE} exercises about what he asked, ordered from the most
    basic to moderately advanced. The first ones anyone could answer after hearing of
    the subject; each next one a small step past the previous. They are his first
    lessons: every exercise must teach him one fact or idea, and together they show
    how far he already gets.

    Cover the subject broadly, as he asked for it. Do not narrow it to one aspect.

    {LEVEL_RULES}

    {EXERCISE_RULES}
    - Write every exercise and option in {language.english_name}.
    - Return only the exercises.
    """
