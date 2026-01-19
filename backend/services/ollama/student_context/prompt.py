def get_student_context_prompt(
    goal_name: str,
    goal_description: str,
    objective_name: str,
    objective_description: str,
    onboarding_prompt: str | None = None,
    questions_answers: list[tuple[str, str]] | None = None
) -> str:
    """
    Generate a prompt to create student context from onboarding data.
    
    Args:
        goal_name: Name of the student's goal
        goal_description: Description of the goal
        objective_name: Name of the first objective
        objective_description: Description of the first objective
        onboarding_prompt: Optional initial prompt from the student
        questions_answers: Optional list of (question, answer) tuples from onboarding
    """
    context_parts = []
    
    if onboarding_prompt:
        context_parts.append(f"Initial goal request: {onboarding_prompt}")
    
    if questions_answers:
        qa_text = "\n".join([f"- {q}: {a}" for q, a in questions_answers])
        context_parts.append(f"Onboarding questions and answers:\n{qa_text}")
    
    context_section = "\n\n".join(context_parts) if context_parts else "No additional onboarding context available."
    
    return f"""
    ## Context
    
    You are an AI Tutor analyzing a new student's profile.
    
    The student has the following goal:
    - Goal Name: {goal_name}
    - Goal Description: {goal_description}
    
    Their first objective is:
    - Objective Name: {objective_name}
    - Objective Description: {objective_description}
    
    {context_section}
    
    ## Task
    
    Based on the information provided, generate a student context profile with two components:
    
    1. **State**: A concise description of the student's current knowledge level, experience, and position in their learning journey. This should capture what they know, what they don't know, and where they are starting from.
    
    2. **Metacognition**: A description of the student's awareness of their own learning process, their understanding of what they need to learn, their motivations, concerns, and learning approach. This captures their thinking about thinking.
    
    ## Format
    
    You will return a JSON object with:
    - state: A string (less than 100 words) describing the student's current state
    - metacognition: A string (less than 100 words) describing the student's metacognitive understanding
    
    Be specific and insightful. Use the language of the student's goal and objective.
    If onboarding data is limited, infer reasonable assumptions based on the goal and objective.
    """
