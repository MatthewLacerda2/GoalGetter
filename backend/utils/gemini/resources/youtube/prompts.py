def get_search_youtube_channels_prompt_plain_text(goal_name: str, goal_description: str, objective_name: str, objective_description: str, student_context: list[str] | None) -> str:
    
    context_list: str = "Here is some context about the student:" + "\n".join([f"- {context}." for context in student_context]) if student_context else ""
    
    return f"""
    ## Task
    
    You are a helpful assistant that searchs for youtube channels recommendations for the user.
        
    The user has the current objective '{objective_name}', with the description '{objective_description}'.
    The goal is '{goal_name}', with the description {goal_description}.
    
    {context_list}    
    
    ## Instructions
    
    You have the Google Search tool at your disposal. Use it to search for youtube channels.
    Only use up to the first 10 search results.
    
    You can use the results or add youtube channels you know about.
    
    You must look for youtube channels as a whole, not just a single video for the objective.
    Look for Youtube channels that shown to teach in the goal or objective. If the Youtube channel is professional, that's even better.
    The Youtube channel MUST be in the student's language.
    The youtube channels MUST be in the same language as the goal name and/or objective name.
        
    ## Output
    
    You will return a list of ResourceSearchResultItem. Each item contains the fields:
    - name: The name of the Youtube channel available.
    - description: A short description of the Youtube channel.
    - language: The language of the Youtube channel
    - link: The Youtube channel URL
    
    You will return a list of ResourceSearchResultItem.
    If no good results are found, return an empty list.
    Return no more than 10 Youtube channels. Prioritize the results ranked first.
    """

def get_search_youtube_channels_prompt(gemini_results_plain_text: str) -> str:
    
    return f"""    
    You are a helpful assistant that formats text into a JSON object.
    
    I will pass you a list of Youtube channels with name, description, language, and link.
    You will format them into a JSON object.
    
    ## Output
    
    You will return a list of ResourceSearchResultItem. Each item contains the fields:
    - name: The name of the Youtube channel available.
    - description: A description of the Youtube channel, in 20 words or less.
    - language: The language of the Youtube channel
    - link: The Youtube channel URL
    
    You will return a list of ResourceSearchResultItem.
    You can just copy the search results as is.
    
    
    Here is the search results of Youtube channels:
    {gemini_results_plain_text}
    """