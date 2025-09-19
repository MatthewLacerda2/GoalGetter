def get_generate_learn_info_prompt(objective_name: str, objective_description: str, informations: list[str]) -> str:
    informations_list = "\n".join([f"- {information}" for information in informations])
    
    return f"""
    ## Context
    
    The user is learning with an objective of '{objective_name}', described as: '{objective_description}'
    You are an experienced expert in the student's chosen field and an AI-Tutor.
    
    
    ## Task
    
    Generate some content to teach the student about the objective.
    Focus on basic information that is relevant.
    If there are many principles to the objective, choose one arbitrarily and focus on it.
    
    Here is some information about the student:
    {informations_list}
    
    The text must be written simply and read simply.
    Focus on providing clear, declarative knowledge (principles and definitions)
    Stick to declarative and relevant knowledge, so the student truly undertands you quickly!
    The content is a basic informative text.
    Do NOT write a personal text, as if you're talking to the student.
    
    
    ## Guidelines
    
    You will return a LearnInfo object. It has the fields:
    - title: The title of the learn info content
    - theme: the subject of the content. Use for querying.
    - content: The information being taught
    
    The title MUST be less than 10 words.
    The theme is just for querying and will not be seen by the student. MUST be less than 10 words.
    
    The title and theme just need the general idea. It's the content that its important.
    
    The content can use markdown.
    Keep the content less than 150 words.
    
    The content must be in the language of the student's objective.
    """