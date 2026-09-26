from backend.core.language import Language
from backend.schemas.goal import ObjectiveAnswer
from backend.services.gemini.output_language import language_name

# How long the goal description the student reads at the end of onboarding may
# be (#173: "o app deve ser breve"). Sixty words is a short paragraph on a phone
# screen: enough for what to study next and why, not enough for a syllabus.
STUDY_PLAN_MAX_WORDS = 60


def get_study_plan_prompt(prompt: str, answers: list[ObjectiveAnswer], language: Language) -> str:

    answers_text = "\n".join([f"- {a.question}: {a.answer}" for a in answers])

    return f"""
    You are a learning consultant on an app that guides users to learn things.

    The user said they want to learn:
    "{prompt}"

    They then answered a few onboarding questions so we can understand them:
    {answers_text}


    ## Task

    Write a short study plan tailored to THIS user. It has two parts:
    - goal_name: a short, clear name for what they will learn
    - description: tell the user the NEXT thing they should study and WHY, based on
      their answers. Frame it as "here's what to focus on next, and here's why".


    ## Writing rules

    - Be brief: the description is at most {STUDY_PLAN_MAX_WORDS} words, and goal_name a few words.
    - You may write the description in Markdown (bold, a short bullet list).
    - Use simple, everyday language. Avoid technical jargon.
    - What the user says about his own level is his opinion, not his level: the app
      measures it from his answers to lessons, so do not build the plan on it as a fact.
    - What he says he wants to reach is not where he stops: the app teaches him as far
      as he can go. Never promise or plan an end point.
    - Write both parts in {language_name(language)}.
    """
