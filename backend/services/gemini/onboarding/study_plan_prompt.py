from backend.schemas.goal import ObjectiveAnswer

def get_study_plan_prompt(prompt: str, answers: list[ObjectiveAnswer]) -> str:

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

    - You may write the description in Markdown (headings, bold, bullet lists).
    - Keep it short: never more than ~400 lines, and ideally much shorter.
    - Use simple, everyday language. Avoid technical jargon.
    - Write in the same language the user used.
    """
