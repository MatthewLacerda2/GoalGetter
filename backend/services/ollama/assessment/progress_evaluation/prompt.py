from typing import List
from backend.models.student_context import StudentContext

def format_student_contexts(contexts: List[StudentContext]) -> str:
    """Format student contexts for the prompt"""
    if not contexts:
        return "No previous student contexts available."
    
    context_parts = []
    for context in contexts:
        parts = []
        if context.state:
            parts.append(f"State: {context.state}")
        if context.metacognition:
            parts.append(f"Metacognition: {context.metacognition}")
        
        if parts:
            context_parts.append("- " + " | ".join(parts))
        else:
            context_parts.append("- (No state or metacognition recorded)")
    
    return "\n".join(context_parts)

def get_progress_evaluation_prompt(
    goal_name: str,
    goal_description: str,
    objective_name: str,
    objective_description: str,
    percentage_completed: float,
    contexts: List[StudentContext]
) -> str:
    """Generate prompt for progress evaluation"""
    formatted_contexts = format_student_contexts(contexts)
    
    return f"""
## Context

The student has a goal: '{goal_name}' - {goal_description}
Current objective: '{objective_name}' - {objective_description}
Current progress: {percentage_completed}%

You are an experienced Tutor evaluating the student's mastery level.

Recent student contexts:
{formatted_contexts}

## Task

Evaluate the student's progress and mastery:

- State: array of strings describing the student's current state/knowledge
- Metacognition: array of strings describing the student's metacognitive awareness
- Percentage Completed: float between 0 and 100

## Important Information About Output

The state[] and metacognition[] arrays will be stored in StudentContext records. Each pair at the same index (state[0] with metacognition[0], state[1] with metacognition[1], etc.) will be saved together in the same context record.

## Constraints for State and Metacognition

- Both arrays must have the same length (same number of elements)
- You can choose to send a state text but keep its corresponding metacognition empty (empty string), and vice-versa
- You can elect not to say anything about state and metacognition (send empty arrays)
- Only include state/metacognition information that is complementary to creating a database of what we know about the user or the user's cognitive behavior
- All state and metacognition texts must be written in third person (e.g., "The student demonstrates..." not "You demonstrate...")
- Focus on factual, observable insights about the student's learning state and cognitive patterns

## Constraints for Percentage Completed

- Percentage must be between 0 and 100
- Must not be less than {percentage_completed}, which is the current percentage completed for the objective.
- 95% means the student is ready to progress to the next objective
- Only give 95% if the student shows great mastery of the current objective and will learn more by moving to the next one
- Increase gradually based on demonstrated understanding and practice

## Format

You will output a JSON object with:
- state: array of strings (each string less than 100 words, written in third person)
- metacognition: array of strings (each string less than 100 words, written in third person)
- percentage_completed: float between 0 and 100

Write in the language of the student's goal and objective.
"""
