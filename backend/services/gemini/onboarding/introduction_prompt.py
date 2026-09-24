def get_introduction_prompt(goal_name: str, description: str) -> str:

    return f"""
    You are writing the welcome screens for someone who just committed to a learning goal.

    Their goal:
    "{goal_name}"

    What they will study:
    {description}


    ## Task

    Write 3 to 5 short "introduction" screens. They are shown one after another, like
    a carousel, while we set up the goal in the background. Their job is to motivate
    the user and set expectations — make them feel excited and understood.

    Each screen has:
    - icon: pick the one icon from the allowed set that best fits the screen.
    - title: a few punchy words.
    - text: one or two warm, encouraging sentences. No fluff.


    ## Writing rules

    - Use simple, everyday language. No technical jargon.
    - Write in the same language the user used in their goal.
    - Keep every screen short — this is a splash, not a lesson.
    """
