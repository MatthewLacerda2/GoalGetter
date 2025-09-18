def get_search_websites_prompt_plain_text(goal_name: str, goal_description: str, objective_name: str, objective_description: str, student_context: list[str] | None) -> str:
    
    context_list: str = "Here is some context about the student:" + "\n".join([f"- {context}." for context in student_context]) if student_context else ""
    
    return f"""
    ## Task
    
    You are a helpful assistant that searchs for website recommendations for the user.
        
    The user has the current objective '{objective_name}', with the description '{objective_description}'.
    The goal is '{goal_name}', with the description {goal_description}.
    
    {context_list}    
    
    ## Instructions
    
    You have the Google Search tool at your disposal. Use it to search for websites available online.
    Only use up to the first 10 search results.
    
    You can use the results or add websites you know about.
    The websites MUST be in the same language as the goal name and/or objective name.
    
    You must look for websites as a whole that teach about the goal or objective. Not a single webpage specific for the objective.
    Just look at the title, description, and a bit of the content if available. If it sounds good and reads well, that's gold.    
        
    ## Output
    
    You will return a list of ResourceSearchResultItem. Each item contains the fields:
    - name: The name of the website available.
    - description: A succinct description of the website, in 20 words or less.
    - language: The language of the website
    - link: The website URL
    
    You will return a list of ResourceSearchResultItem.
    If no good results are found, return an empty list.
    Return no more than 10 websites. Prioritize the results ranked first.
    """

def get_search_websites_prompt(gemini_results_plain_text: str) -> str:
    
    return f"""    
    You are a helpful assistant that formats text into a JSON object.
    
    I will pass you a list of websites with name, description, language, and link.
    You will format them into a JSON object.
    
    ## Output
    
    You will return a list of ResourceSearchResultItem. Each item contains the fields:
    - name: The name of the website available.
    - description: A short description of the website.
    - language: The language of the website.
    - link: The website URL.
    
    You will return a list of ResourceSearchResultItem.
    You can just copy the search results as is.
    
    
    Here is the search results:
    {gemini_results_plain_text}
    """