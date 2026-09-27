from backend.core.config import settings
from backend.core.language import Language
from backend.services.gemini.lesson.schema import AnsweredQuestion
from backend.services.gemini.student_context.schema import GeminiStudentContext

# What every exercise must be, lesson or placement (the user, 2026-09-26).
# "Exercise", not "question", on purpose: an item may be an instruction ("Pick
# the Middle Eastern capital"), and a model told "question" ends everything in a
# question mark. The option order is shuffled in code after it answers
# (services/lessons/shuffle.py), so where it puts the right one does not matter.
# Rules 1 and 2 of #173, for any prompt that writes exercises for him.
LEVEL_RULES = """His level is what he got right, not what he or the app's reading says about it:
    a self-assessment is his opinion. And what he says he wants to reach is not a
    ceiling: the app teaches him as far as he can go."""

EXERCISE_RULES = """Every exercise:
    - Is multiple choice: exactly 4 options, one right; give its index as
      correct_option_index (0-3).
    - May be a question or an instruction ("Pick the ...", "Which of these ...").
    - Is at most 20 words, and so is each option.
    - Is simple and plain: no jargon he has not been taught by an earlier exercise.
    - Has plain options: just the thing itself ("Heart", not "The beating heart"), no
      adjective or filler that hints at the answer. All four the same kind of thing.
    - Has wrong options that are plausible - real confusions a learner has - so nothing
      gives the answer away but knowing it."""


def format_contexts(contexts: list[GeminiStudentContext]) -> str:
    """The student's still-valid contexts, newest first. They are written about
    the person and not about this goal, so several may apply at once."""
    if not contexts:
        return "No reading of this student has been written yet."
    return "\n".join(
        [f'- State: "{c.state}" - Metacognition: "{c.metacognition}"' for c in contexts]
    )


def format_right(answered: list[AnsweredQuestion]) -> str:
    """The questions he got right, plain: what he already holds, shown as his
    own material rather than as a number."""
    if not answered:
        return "None yet."
    return "\n".join([f'- "{a.question}" -> he answered "{a.correct}"' for a in answered])


def format_wrong(answered: list[AnsweredQuestion]) -> str:
    """The questions he got wrong, each with the option he chose.

    The chosen option is the point: it is what he believes instead of the right
    answer, and two students who miss the same question for different reasons
    need different questions next.
    """
    if not answered:
        return "None yet."
    return "\n".join(
        [
            f'- "{a.question}" -> he chose "{a.chosen}", and the answer was "{a.correct}"'
            for a in answered
        ]
    )


def get_lesson_generation_prompt(
    goal_name: str,
    goal_description: str,
    frontier: str,
    contexts: list[GeminiStudentContext],
    answered_right: list[AnsweredQuestion] | None,
    answered_wrong: list[AnsweredQuestion] | None,
    language: Language,
) -> str:
    return f"""
    You write exercises for a student learning "{goal_name}". Their purpose is that he
    learns something every day, even if it is little: they teach, they do not test.

    What he asked for on day one: "{goal_description}"
    What to teach him now: "{frontier}"

    What the app has read about him (it covers everything he studies, not only this
    subject; use it to judge how he learns, never as a topic):
    {format_contexts(contexts)}

    Exercises of this subject he got right - what he has shown he knows:
    {format_right(answered_right or [])}

    Exercises he got wrong, with the option he picked - what he believes instead:
    {format_wrong(answered_wrong or [])}

    Write exactly {settings.QUESTIONS_PER_GENERATION} exercises, as simple as possible while one
    step past what he got right. With nothing right yet, that is the most basic of the
    subject. Some may revisit what he got wrong, from another angle.

    {LEVEL_RULES}

    {EXERCISE_RULES}
    - Write every exercise and option in {language.english_name}.
    - Return only the exercises.
    """
