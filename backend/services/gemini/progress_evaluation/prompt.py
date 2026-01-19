from typing import List

from backend.models.student_context import StudentContext


def format_student_contexts(contexts: List[StudentContext]) -> str:
    """Format student contexts for the prompt."""
    if not contexts:
        return "No previous student contexts available."

    context_parts: list[str] = []
    for context in contexts:
        parts: list[str] = []
        if getattr(context, "state", None):
            parts.append(f"State: {context.state}")
        if getattr(context, "metacognition", None):
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
    contexts: List[StudentContext],
) -> str:
    """Generate prompt for progress evaluation."""
    formatted_contexts = format_student_contexts(contexts)

    return f"""
## Context

You are an experienced Tutor evaluating the student's mastery level.

The student has a goal: '{goal_name}' - {goal_description}
Current objective: '{objective_name}' - {objective_description}
Current progress at the objective: {percentage_completed}%

## Task

Evaluate the student's progress and mastery:

- State: student's current state/knowledge
- Metacognition: student's cognitive awareness
- Percentage Completed: student's current progress in the objective

# Guidelines

The percentage_completed measures the student's mastery of the objective.

- Both arrays must have the same length (same number of elements)
- You can choose to send a state text but keep its corresponding metacognition empty (empty string), and vice-versa
- You can elect not to say anything about state and metacognition (send empty arrays)
- Only include state/metacognition information that is complementary to creating a database of what we know about the user or the user's cognitive behavior
- All state and metacognition texts must be written in third person (e.g., "The student demonstrates..." not "You demonstrate...")
- Focus on factual, observable insights about the student's learning state and cognitive patterns

Here is some information about the student:
{formatted_contexts}

- Percentage_completed must be between 0-100.
- Must not be less than the current evaluation of {percentage_completed}.
- An evaluation of 95% means the student will learn more by moving to the next objective

Be direct, blunt and succinct.
Each state and metacognition must be less than 20 words.

# Format

You will output a JSON object with:
- state[]: array of strings (each string less than 100 words, written in third person)
- metacognition[]: array of strings (each string less than 100 words, written in third person)
- percentage_completed: float between 0-100

The state and metacognition arrays must have the same length (same number of elements).
Each element in the state has a corresponding element in the metacognition array, of same index.

Write in the language of the student's goal and objective.
"""

