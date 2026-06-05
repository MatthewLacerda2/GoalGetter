def get_student_context_prompt(
    goal_name: str,
    goal_description: str,
    onboarding_prompt: str | None = None,
    questions_answers: list[tuple[str, str]] | None = None
) -> str:
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
    
    {context_section}
    
    ## Task
    Based on the information provided, generate an initial student context profile with two components:
    
    1. **State**: A concise description of the student's current knowledge level, experience, and position in their learning journey. This should capture what they know, what they don't know, and where they are starting from.
    
    2. **Metacognition**: A description of the student's awareness of their own learning process, their understanding of what they need to learn, their motivations, concerns, and learning approach. This captures their thinking about thinking.
    
    ## Format
    You will return a JSON object with:
    - state: A string (less than 100 words) describing the student's current state
    - metacognition: A string (less than 100 words) describing the student's metacognitive understanding
    
    Be specific and insightful. Use the language of the student's goal.
    If onboarding data is limited, infer reasonable assumptions based on the goal.
    """

def get_periodic_student_context_prompt(
    goal_name: str,
    goal_description: str,
    previous_state: str,
    previous_metacognition: str,
    recent_lesson_results: list[dict],
    recent_chat_history: list[dict]
) -> str:
    lessons_formatted = "\n".join([
        f"- Question: {res.get('question')}\n  Selected: {res.get('selected_option')}\n  Is Correct: {res.get('is_correct')}\n  Time Spent: {res.get('time_spent')}s"
        for res in recent_lesson_results
    ]) if recent_lesson_results else "No recent lesson answers."

    chat_formatted = "\n".join([
        f"User: {msg.get('prompt')}\nTutor: {msg.get('tutor_response')}"
        for msg in recent_chat_history
    ]) if recent_chat_history else "No recent chat history."

    return f"""
    <Context>
    You are an AI Tutor evaluating a student's learning progress.
    Goal they are studying: "{goal_name}" (described as: "{goal_description}")
    
    Previous Student Context:
    - State (Knowledge Level): "{previous_state}"
    - Metacognition (Awareness/Motivations): "{previous_metacognition}"
    
    Recent Study Lesson Answers (Student's performance):
    {lessons_formatted}
    
    Recent Chat Tutor Messages (Interactions showing conceptual understanding/questions):
    {chat_formatted}
    </Context>

    <Task>
    Analyze the student's recent performance and dialogue to generate an updated Student Context profile (State and Metacognition).
    </Task>

    <Guidelines>
    - **State**: Update the student's knowledge level, identifying new concepts mastered, persistent errors, and current weaknesses or focus areas.
    - **Metacognition**: Update their learning style, attitude, cognitive load, reactions, and focus based on their chat messages and time spent on questions.
    - Keep both descriptions concise (under 100 words each).
    - If no new study activity or chat is present, keep the state similar to the previous state but reflect their current stagnation.
    - Write the response in the student's language.
    </Guidelines>
    """
