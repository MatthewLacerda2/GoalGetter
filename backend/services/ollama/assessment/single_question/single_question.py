import ollama
from ollama._types import ResponseError
from backend.services.ollama.assessment.single_question.schema import OllamaSingleQuestionReview
from backend.services.ollama.assessment.single_question.prompt import get_single_question_review_prompt

def ollama_generate_question_review(
    question: str, answer: str
) -> OllamaSingleQuestionReview:
    
    model = "gpt-oss:120b-cloud"
    full_prompt = get_single_question_review_prompt(question, answer)

    try:
        response: ollama.ChatResponse = ollama.chat(
            model=model,
            stream=False,
            messages=[
                {
                    "role": "user",
                    "content": full_prompt
                }
            ],
            format=OllamaSingleQuestionReview.model_json_schema()
        )
        
        json_response = response.message.content
        
        return OllamaSingleQuestionReview.model_validate_json(json_response)
    except ResponseError as e:
        raise Exception(f"Ollama API error {e.status_code}: {str(e)}")
    except Exception as e:
        raise Exception(f"Unexpected error: {type(e).__name__}: {e}")

if __name__ == "__main__":
    print(ollama_generate_question_review(
        question="Explique o que é Hierarquia das Normas e qual norma ocupa o topo no ordenamento jurídico brasileiro.",
        answer="É o grau de aplicação de cada norma na esfera, seja federal, estadual e municipal, e quem tá no topo é a constituição",
    ))
