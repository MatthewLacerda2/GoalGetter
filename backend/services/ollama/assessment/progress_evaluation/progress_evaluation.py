from typing import List
import ollama
from ollama._types import ResponseError
from backend.services.ollama.assessment.progress_evaluation.prompt import get_progress_evaluation_prompt
from backend.services.ollama.assessment.progress_evaluation.schema import OllamaProgressEvaluation, OllamaProgressEvaluationResponse
from backend.models.student_context import StudentContext

def ollama_progress_evaluation(
    goal_name: str,
    goal_description: str,
    objective_name: str,
    objective_description: str,
    percentage_completed: float,
    contexts: List[StudentContext]
) -> OllamaProgressEvaluationResponse:
    """
    Generate progress evaluation using Ollama AI.
    
    Args:
        goal_name: Name of the student's goal
        goal_description: Description of the goal
        objective_name: Name of the current objective
        objective_description: Description of the current objective
        percentage_completed: Current percentage completed for the objective
        contexts: List of student contexts (latest 8, ordered by objective then created_at)
    
    Returns:
        OllamaProgressEvaluationResponse with state[], metacognition[], percentage_completed, and ai_model
    """
    model = "qwen3-vl:235b-cloud"
    full_prompt = get_progress_evaluation_prompt(
        goal_name=goal_name,
        goal_description=goal_description,
        objective_name=objective_name,
        objective_description=objective_description,
        percentage_completed=percentage_completed,
        contexts=contexts
    )

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
            format=OllamaProgressEvaluation.model_json_schema()
        )
        
        json_response = response.message.content
        
        evaluation = OllamaProgressEvaluation.model_validate_json(json_response)
        
        # Ensure arrays have same length (pad with empty strings if needed)
        state_array = evaluation.state if evaluation.state else []
        metacognition_array = evaluation.metacognition if evaluation.metacognition else []
        
        max_length = max(len(state_array), len(metacognition_array))
        state_array.extend([""] * (max_length - len(state_array)))
        metacognition_array.extend([""] * (max_length - len(metacognition_array)))
        
        return OllamaProgressEvaluationResponse(
            state=state_array,
            metacognition=metacognition_array,
            percentage_completed=evaluation.percentage_completed,
            ai_model=model
        )
    except ResponseError as e:
        raise Exception(f"Ollama API error {e.status_code}: {str(e)}")
    except Exception as e:
        raise Exception(f"Unexpected error: {type(e).__name__}: {e}")


# You can call this test with
# python -m backend.services.ollama.assessment.progress_evaluation.progress_evaluation
if __name__ == "__main__":
    from datetime import datetime, timezone

    # Create mock StudentContext objects
    class MockStudentContext:
        def __init__(self, state: str, metacognition: str, objective_id: str = None):
            self.state = state
            self.metacognition = metacognition
            self.objective_id = objective_id
            self.created_at = datetime.now(timezone.utc)
            self.is_still_valid = True

    # Create sample student contexts
    mock_contexts = [
        MockStudentContext(
            state="The student demonstrates strong understanding of basic flight controls and has been practicing consistently in Flight Simulator 2020.",
            metacognition="The student is aware of their progress and actively seeks to improve their landing techniques, recognizing that precision is key.",
            objective_id="current_objective_id"
        ),
        MockStudentContext(
            state="The student has mastered straight and level flight, but struggles with crosswind landings.",
            metacognition="The student understands that crosswind landings require more practice and is focusing on maintaining proper aircraft alignment during approach.",
            objective_id="current_objective_id"
        ),
        MockStudentContext(
            state="The student successfully completed several touch-and-go exercises and is building confidence with takeoff procedures.",
            metacognition="The student recognizes that repetition is important for muscle memory and continues to practice despite initial challenges.",
            objective_id="current_objective_id"
        ),
        MockStudentContext(
            state="The student has been studying aviation theory alongside simulator practice, understanding airspeed management during landing.",
            metacognition="The student is connecting theoretical knowledge with practical application, which shows good learning integration.",
            objective_id="previous_objective_id"
        ),
    ]

    result = ollama_progress_evaluation(
        goal_name="Become an Airline Pilot",
        goal_description="The student's ultimate goal is to become a professional airline pilot, requiring comprehensive flight training, certifications, and thousands of flight hours.",
        objective_name="Master Takeoff and Landing in Flight Simulator 2020",
        objective_description="Learn and practice proper takeoff and landing procedures in Flight Simulator 2020, including normal takeoffs, landings, crosswind techniques, and emergency procedures.",
        percentage_completed=70.0,
        contexts=mock_contexts
    )

    print("=" * 80)
    print("PROGRESS EVALUATION RESULT")
    print("=" * 80)
    print(f"\nPercentage Completed: {result.percentage_completed}%")
    print(f"AI Model: {result.ai_model}")
    print(f"\nNumber of State/Metacognition Pairs: {len(result.state)}")
    print("\n" + "-" * 80)

    for i, (state, metacognition) in enumerate(zip(result.state, result.metacognition), 1):
        print(f"\nPair {i}:")
        if state:
            print(f"  State: {state}")
        else:
            print(f"  State: (empty)")
        
        if metacognition:
            print(f"  Metacognition: {metacognition}")
        else:
            print(f"  Metacognition: (empty)")

    print("\n" + "=" * 80)
