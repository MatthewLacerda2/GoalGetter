from backend.core.language import Language
from backend.services.gemini.output_language import language_name

# How many questions onboarding asks (#173, "por enquanto"): the time each
# student spends per question (#174) is what will decide the right number later.
ONBOARDING_QUESTIONS = 8

# The longest a question, or any one of its options, may be. Words, not
# characters. Only the prompt asks for it - see `onboarding.py` for why.
MAX_WORDS = 20


def get_onboarding_questions_prompt(
    goal_name: str, goal_description: str, language: Language
) -> str:
    return f"""
    <Context>
    You are an AI Tutor creating an onboarding experience for a student.
    The student wants to learn: "{goal_name}"
    Description of their goal: "{goal_description}"
    </Context>

    <Task>
    Your task is to generate exactly {ONBOARDING_QUESTIONS} multiple-choice onboarding questions.
    These questions will help understand the student's background and what draws him to the goal area.
    </Task>

    <Guidelines>
    - Each question must have exactly 4 options: Option A, Option B, Option C, and Option D.
    - There is NO "right" answer.
    - Do not ask the student to rate his own level: what he says about himself is his opinion,
      and the lessons will measure him. Ask about concrete things he has done, used or met instead.
    - Do not ask how far he wants to go: his ambition is not a ceiling, and the app
      teaches him as far as he can go.
    - Between them, the questions cover:
      1. What he has already done or practised in the topic
      2. Specific areas of interest within the goal
      3. What he wants to use it for
      4. Related things he already knows
      5. How he likes to learn
    - Each question, and each option, is at most {MAX_WORDS} words. Shorter is better.
    - Keep the questions and options simple, direct, and easy to understand.
    - Write every question and option in {language_name(language)}.
    </Guidelines>
    """
