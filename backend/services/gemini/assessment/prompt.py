def generate_subjective_questions_prompt(objective_name: str, objective_description: str, goal_name: str, num_questions: int) -> str:
    
    return f"""
    ## Context
    
    The user has an objective of '{objective_name}', described as: '{objective_description}'
    The ultimate goal is '{goal_name}'
    You are an experienced expert in the student's chosen field.
    
    
    ## Task
    
    You must generate a list of {num_questions} subjective questions.
    We are assessing the student's understanding in the objective.
    These questions are meant to assess the student's foundation in the objective.
    
    Ask basic questions that require the principles of the objective for an answer.
    These questions must give opportunity to the student to show he has made progress.
    
    You can ask specific questions, but the body of questions MUST assess the student's grasp on the objective.
    You can ask questions, experiences, or questions that require basic reasoning.
    
    Write simple questions that only need concise answers.    
    Your question must be 20 words or less.
    Expect answers of no more than 50 words.
    
    
    # Output
    
    You will return a list of strings. Each string is a question.
    You must generate at least {num_questions} questions, and no more than {num_questions + 5}. Whatever you think provides a good assessment.
    
    The questions MUST be in the language of the user's objective.
    """