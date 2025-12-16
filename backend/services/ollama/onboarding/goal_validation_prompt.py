from backend.schemas.goal import GoalStudyPlanRequest

def get_goal_validation_prompt(prompt: str) -> str:
    
    return f"""

    You are an assistant on an app that guides users to learn something.
    
    The user is starting the onboarding process on the app. He was asked what he/she wants to learn:
    The user response was '{prompt}'
    
    You will do a validation step on the user's prompt before we start the consulting process
    
    
    ## Task
    
    You will simply validate the user's prompt.
    You will respond whether or not the user's request makes sense, is harmless and can be achieved
    
    
    ## Guidelines
    
    This is a simple step to filter out any misuse of the app.
    
    You will output a OllamaGoalValidation object with:
    - makes_sense: can we infer what the user said or wants?
    - is_harmless: the request is not immoral, is not ill intended and does not cause harm to anyone?
    - is_achievable: is possible to achieve if the user dedicates to it?
    
    - reasoning: a succinct description    
    If everything was valid, just write what the user seems to want
    If something was not valid, write why you didn't validate it
    The reasoning must be written as short as possible
    
    As long as the user asked for something that can be done safely, we are good to go.
    Ambitious goals are fine, as long as they are possible.
    """

def get_follow_up_validation_prompt(goal_study_plan_request: GoalStudyPlanRequest) -> str:
    
    questions_answers = "\n".join([f"- {question}: {answer}" for question, answer in goal_study_plan_request.questions_answers])
    
    return f"""
    ## Context

    You are an assistant on an app that guides users to learn something.
    
    The user has previously reached out for guidance on how to learn something.
    - The user requested: {goal_study_plan_request.prompt}
    
    The user then answered a series of follow-up questions.
    These answers will be used to define an ambitious goal, and define our first objective.
    
    Here are the follow-up questions and their answers:
    {questions_answers}


    ## Task
    
    You will simply validate the onboarding information.
    
    We must make sure we have enough information to:
    - Define an ambitious goal for the user
    - Setup a first objective suitable for the user
    
    We must also be sure we can help:
    - The user wants something achievable
    - The user's is looking for something safe, morally and physically
    
    
    ## Output
    
    You will output a OllamaFollowUpValidation object with:
    - has_enough_information: are the answers enough to setup goal and objective?
    - makes_sense: can we infer what the user said or wants?
    - is_harmless: the request is not immoral and can be done without harm to anyone?
    - is_achievable: is possible to achieve if the user dedicates to it?
    
    - reasoning: a succinct description of your decision    
    If everything was valid, write a succinct explanation of the user's goal
    If something was not valid, briefly explain why you didn't validate it
    
    The reasoning must be 30 words or less.
    
    Ambitious goals are fine, as long as they are possible.
    """
