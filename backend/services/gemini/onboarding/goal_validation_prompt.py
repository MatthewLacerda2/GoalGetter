def get_goal_validation_prompt(prompt: str) -> str:
    
    return f"""

    You are an assistant on an app that guides users to learn something.
    
    The user is starting the onboarding process on the app. He was asked what he/she wants to learn:
    The user response was '{prompt}'
    
    You will do a validation step on the user's prompt before we start the consulting process
    
    
    ## Task
    
    Your job is to simply validate the user's prompt.
    You will assure the user's request makes sense, is not harmful and can be achieved
    
    
    ## Guidelines
    
    This is a simple step to filter out any misuse of the app.
    
    You will output a GoalValidation object with:
    - makes_sense: can we infer what the user said or wants?
    - is_harmless: the request is not immoral and can be done without harm to anyone?
    - is_achievable: is possible to achieve if the user dedicates to it?
    
    As long as the user asked for something that can be done safely, we are good to go.
    Ambitious goals are fine, as long as they are possible.
    """

def get_follow_up_validation_prompt() -> str:
    pass