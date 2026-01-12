from typing import List

def generate_multiple_choice_questions_prompt(objective_name: str, objective_description: str, previous_objectives: List[str], informations: List[str], num_questions: int) -> str:
    
    informations_list: str = "\n".join([f"- {information}" for information in informations])
    previous_objectives_list: str = "\n".join([f"- {objective}" for objective in previous_objectives])
    
    return f"""
    ## Context
    
    The user is learning towards an objective of '{objective_name}', described as: '{objective_description}'
    You are an experienced expert in the user's chosen field and an AI-Tutor.
    
    
    ## Task
    
    You must generate a list of {num_questions} multiple choice questions.
    You must use a didatic and constructive approach.
    These questions are meant for teaching, not for evaluating the student.
    
    Here is some information about the user:
    {informations_list}
    
    If there is anything you are not sure the student knows yet, focus on it.
    The questions should reinforce the student's knowledge and build a strong foundation.
    
    For reference, the student has a solid grasp on these previous objectives:
    {previous_objectives_list}
    

    ## Format
    
    You will return a OllamaMultipleChoiceQuestionsList. Each item in the list has the fields:
    - question: The question
    - choices: A list of 4 choices
    - correct_answer_index: The zero-based index of the correct answer
    
    Each question MUST be less than 30 words.
    The first choice is at index 0.
    
    The questions MUST be in the language of the user's objective.
    """
