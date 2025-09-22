def get_search_ebooks_prompt_plain_text(goal_name: str, goal_description: str, objective_name: str, objective_description: str, student_context: list[str] | None) -> str:
    
    context_list: str = "Here is some context about the student:" + "\n".join([f"- {context}." for context in student_context]) if student_context else ""
    
    return f"""
    ## Task
    
    You are a helpful assistant that searches ebooks online for the user.
        
    The user has the current objective '{objective_name}', with the description '{objective_description}'.
    The goal is '{goal_name}', with the description {goal_description}.
    
    {context_list}
    
    
    ## Instructions
    
    You have the Google Search tool at your disposal. Use it to search for ebooks available online.
    Inserting 'filetype:pdf' at the end of the search queries helps yield better results.
    Only output links directly copied from the Google Search tool results
    
    Just look at the title, description, and a bit of the content if available. If it sounds good and reads well, that's gold.
        
    The links MUST end in '.pdf'.
    The ebooks MUST be in the same language as the goal name and/or objective name.
    If the link doesn't end in '.pdf', forget it. If it's not in the language of the goal or objective, forget it.
    
    
    ## Output
    
    You will return a list of ResourceSearchResultItem. Each item contains the fields:
    - name: The name of the ebook available.
    - description: A description of the ebook, in 20 words or less. Could be in the link description or what you understood that the book is about.
    - language: The language of the ebook
    - link: The link to the pdf file
    
    You will return a list of ResourceSearchResultItem.
    If no results are found, return an empty list.
    Return no more than 10 results. Prioritize the results ranked first.
    """

def get_search_ebooks_prompt(gemini_results_plain_text: str) -> str:
    
    return f"""    
    You are a helpful assistant that formats text into a JSON object.
    
    I will pass you a list of ebooks with name, description, language, and link.
    You will format them into a JSON object.
    
    
    ## Output
    
    You will return a list of ResourceSearchResultItem. Each item contains the fields:
    - name: The name of the ebook available.
    - description: The description of the ebook.
    - language: The language of the ebook.
    - link: The link to the pdf file.
    
    You will return a list of ResourceSearchResultItem.
    You can just copy the search results as is.
    
    Here is the search results:
    {gemini_results_plain_text}
    """