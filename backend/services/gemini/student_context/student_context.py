from backend.utils.gemini.gemini_configs import get_client, get_gemini_config
from backend.services.gemini.student_context.schema import GeminiStudentContext, GeminiStudentContextResponse
from backend.services.gemini.student_context.prompt import get_student_context_prompt

def gemini_generate_student_context(
    goal_name: str,
    goal_description: str,
    objective_name: str,
    objective_description: str,
    onboarding_prompt: str | None = None,
    questions_answers: list[tuple[str, str]] | None = None
) -> GeminiStudentContextResponse:
    """
    Generate student context using Gemini AI.
    
    Args:
        goal_name: Name of the student's goal
        goal_description: Description of the goal
        objective_name: Name of the first objective
        objective_description: Description of the first objective
        onboarding_prompt: Optional initial prompt from the student
        questions_answers: Optional list of (question, answer) tuples from onboarding
    
    Returns:
        GeminiStudentContextResponse with state, metacognition, and ai_model
    """
    client = get_client()
    model = "gemini-2.5-flash"
    config = get_gemini_config(GeminiStudentContext.model_json_schema())
    config.temperature = 1
    
    full_prompt = get_student_context_prompt(
        goal_name=goal_name,
        goal_description=goal_description,
        objective_name=objective_name,
        objective_description=objective_description,
        onboarding_prompt=onboarding_prompt,
        questions_answers=questions_answers
    )
    
    response = client.models.generate_content(
        model=model, contents=full_prompt, config=config
    )
    
    json_response = response.text
    
    context = GeminiStudentContext.model_validate_json(json_response)
    return GeminiStudentContextResponse(
        state=context.state,
        metacognition=context.metacognition,
        ai_model=model
    )
