from backend.utils.gemini.gemini_configs import get_client, get_gemini_config
from backend.services.gemini.assessment.single_question.schema import GeminiSingleQuestionReview
from backend.services.gemini.assessment.single_question.prompt import get_single_question_review_prompt

def gemini_generate_question_review(
    question: str, answer: str
) -> GeminiSingleQuestionReview:
    
    client = get_client()
    model = "gemini-2.5-flash"
    config = get_gemini_config(GeminiSingleQuestionReview.model_json_schema())
    full_prompt = get_single_question_review_prompt(question, answer)

    response = client.models.generate_content(
        model=model, contents=full_prompt, config=config
    )
    
    json_response = response.text
    
    return GeminiSingleQuestionReview.model_validate_json(json_response)

if __name__ == "__main__":
    print(gemini_generate_question_review(
        question="What is a diffusion vision model?",
        answer="It's an AI that draws a picture by drawing it fully and then improvin in incremental steps",
    ))