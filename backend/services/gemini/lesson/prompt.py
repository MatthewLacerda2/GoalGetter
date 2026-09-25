from backend.services.gemini.lesson.schema import AnsweredQuestion
from backend.services.gemini.student_context.schema import GeminiStudentContext
from backend.utils.envs import QUESTIONS_PER_GENERATION


def format_contexts(contexts: list[GeminiStudentContext]) -> str:
    """The student's still-valid contexts, newest first. They are written about
    the person and not about this goal (#87), so several may apply at once."""
    if not contexts:
        return "No reading of this student has been written yet."
    return "\n".join(
        [f'- State: "{c.state}" - Metacognition: "{c.metacognition}"' for c in contexts]
    )


def format_right(answered: list[AnsweredQuestion]) -> str:
    """The questions he got right, plain: what he already holds, shown as his
    own material rather than as a number (#135)."""
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
    rating: int,
    target_difficulty: int,
    contexts: list[GeminiStudentContext],
    answered_right: list[AnsweredQuestion] | None = None,
    answered_wrong: list[AnsweredQuestion] | None = None,
) -> str:
    return f"""
    <Context>
    You are an AI Tutor creating study questions for a student.
    The student's goal: "{goal_name}"
    What he asked for on day one: "{goal_description}"
    **What to teach him now - his current frontier: "{frontier}"**
    The student's current skill rating: {rating} (like a chess rating; higher rating means more advanced/difficult questions are expected)
    **Write these questions at difficulty {target_difficulty}**, above his current rating on purpose: this batch is not the lesson he does tomorrow, it is what he moves on to once he has worked through what he already has.

    What the app knows about this learner - their mastery and gaps (State), and
    how they think and react (Metacognition). It is written about the person,
    so it covers everything they study, not only this goal:
    {format_contexts(contexts)}

    Questions of this goal he has answered correctly - what he already holds:
    {format_right(answered_right or [])}

    Questions of this goal he has answered wrongly, with the option he picked -
    what he believes instead:
    {format_wrong(answered_wrong or [])}
    </Context>

    <Task>
    Generate a list of exactly {QUESTIONS_PER_GENERATION} multiple-choice study questions customized to the student's current needs, skill rating, and weaknesses.
    </Task>

    <Guidelines>
    - Each question must have exactly 4 options: Option A, Option B, Option C, and Option D.
    - One option must be the correct option, and its index must be specified as correct_option_index (0 for A, 1 for B, 2 for C, 3 for D).
    - Match the difficulty of the questions to the target difficulty ({target_difficulty}), not to what he is answering comfortably today.
    - **How much of this batch revisits what he keeps getting wrong and how much of it takes him forward is your judgement**, from the frontier, the questions above and what the context says about him. There is no fixed ratio.
    - Target the questions directly at fixing the student's weaknesses/flaws described in their State, or challenging their cognitive style as noted in their Metacognition.
    - **Ask about the frontier.** The day-one description is background: it
      says where the student came from, not what to ask him about. A goal has
      no finish line, and the frontier is where he has been taken since.
    - The questions are about this goal only. The student's context may mention other subjects they study; use it to judge how they learn, never as a topic to ask about.
    - Keep questions educational and didactically sound.
    - Write the questions in the user's language.
    </Guidelines>
    """
