from backend.utils.gemini.gemini_configs import get_client, get_gemini_config
from backend.utils.envs import GEMINI_FAST_MODEL
from backend.services.gemini.student_context.schema import GeminiStudentContext, GeminiStudentContextResponse
from backend.services.gemini.student_context.prompt import get_student_context_prompt, get_periodic_student_context_prompt

def gemini_generate_student_context(
    goal_name: str,
    goal_description: str,
    onboarding_prompt: str | None = None,
    questions_answers: list[tuple[str, str]] | None = None
) -> GeminiStudentContextResponse:
    """Generate initial student context from onboarding data."""
    client = get_client()
    model = GEMINI_FAST_MODEL
    config = get_gemini_config(GeminiStudentContext.model_json_schema())
    
    full_prompt = get_student_context_prompt(
        goal_name=goal_name,
        goal_description=goal_description,
        onboarding_prompt=onboarding_prompt,
        questions_answers=questions_answers
    )
    
    response = client.models.generate_content(
        model=model, contents=full_prompt, config=config
    )
    
    context = GeminiStudentContext.model_validate_json(response.text)
    return GeminiStudentContextResponse(
        state=context.state,
        metacognition=context.metacognition,
        ai_model=model
    )

def gemini_generate_periodic_student_context(
    goal_name: str,
    goal_description: str,
    previous_state: str,
    previous_metacognition: str,
    recent_lesson_results: list[dict],
    recent_chat_history: list[dict]
) -> GeminiStudentContextResponse:
    """Generate updated student context periodically based on performance and chat history."""
    client = get_client()
    model = GEMINI_FAST_MODEL
    config = get_gemini_config(GeminiStudentContext.model_json_schema())
    
    full_prompt = get_periodic_student_context_prompt(
        goal_name=goal_name,
        goal_description=goal_description,
        previous_state=previous_state,
        previous_metacognition=previous_metacognition,
        recent_lesson_results=recent_lesson_results,
        recent_chat_history=recent_chat_history
    )
    
    response = client.models.generate_content(
        model=model, contents=full_prompt, config=config
    )
    
    context = GeminiStudentContext.model_validate_json(response.text)
    return GeminiStudentContextResponse(
        state=context.state,
        metacognition=context.metacognition,
        ai_model=model
    )
