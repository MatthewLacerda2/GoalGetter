def get_define_objective_prompt(goal_name: str, goal_description: str, latest_objective: str, latest_objective_description: str, student_context: list[str]) -> str:
    
    context_list: str = "\n".join([f"- {context}" for context in student_context])
    
    return f"""
    ## Context
    
    The user has previously reached out for guidance on how to achieve the goal '{goal_name}'.
    - The full goal description is: {goal_description}
    
    The user has a Tutor AI that generates lessons, periodically chats, and evaluates the user's progress.
    - The User's recently accomplished the last objective of '{latest_objective}', described as: '{latest_objective_description}'
    
    Here is some context about the user:
    {context_list}
    
    
    ## Task
    
    You are an experienced expert in the user's chosen field, who will act as an AI-Tutor.
    You must define the next objective towards the goal.
    
    The objective is a small next step towards the goal, right above the user's current knowledge level.
    It must be self-contained, meaning it's a single step that doesn't require others to be completed first.
    
    The objective must have a pedagogical take and be an incremental small step.
    After achieving it, it's expected the user will be more independent and with a strong foundation.
    
        
    ## Format
    
    You will return a OllamaObjective. It has the fields:
    - name: The name of the objective
    - description: A detailed description of the objective
    
    The name is just meant to quickly identify the objective.
    The name MUST be simple, and no more than 10 words.
    
    The description MUST be detailed
    The description MUST describe only the objective, not it's purpose nor the student.
    Although the objective is custom tailored for the student, the description MUST address only the objective.
    The description is a single paragraph, not written in markdown.
    
    The objective must be in the language of the user's goal and objective.
    """
