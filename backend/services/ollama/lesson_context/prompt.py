from typing import List, Optional

def format_questions_answers(questions_answers: List[tuple[str, str]]) -> str:
    """Format questions and answers for the prompt"""
    if not questions_answers:
        return "No questions and answers available."
    
    qa_parts = []
    for question, answer in questions_answers:
        qa_parts.append(f"-question: {question}\nanswer: {answer}")
    
    return "\n".join(qa_parts)

def get_lesson_context_prompt(
    goal_name: str,
    goal_description: str,
    objective_name: str,
    objective_description: str,
    questions_answers: List[tuple[str, str]],
    student_context: Optional[List[str]] = None
) -> str:
    """Generate prompt for lesson context generation"""
    formatted_qa = format_questions_answers(questions_answers)
    context_list: str = ("Here is some context about the student:\n" + "\n".join([f"- {context}." for context in student_context])) if student_context else ""
    
    return f"""
## Context

You are an experienced Tutor analyzing lesson answers to extract insights about the student's learning state and cognitive patterns.

The student has a goal: '{goal_name}' - {goal_description}
Current objective: '{objective_name}' - {objective_description}

{context_list}

## Task

Analyze the lesson questions and answers to generate:

- State: student's current state/knowledge based on their answers
- Metacognition: student's cognitive awareness and learning patterns observed in their responses

## Guidelines

- Both arrays must have the same length (same number of elements)
- You can choose to send a state text but keep its corresponding metacognition empty (empty string), and vice-versa
- You can elect not to say anything about state and metacognition (send empty arrays)
- Only include state/metacognition information that is complementary to creating a database of what we know about the user or the user's cognitive behavior
- All state and metacognition texts must be written in third person (e.g., "The student demonstrates..." not "You demonstrate...")
- Focus on factual, observable insights about the student's learning state and cognitive patterns derived from the answers
- Consider the accuracy of answers, response patterns, and learning progress revealed
- Only write student context which is new information. If you have nothing to add, just send an empty array
- Focus on sending high density-value data, not high-volume

Here are the lesson questions and answers:
{formatted_qa}

Be direct, blunt and succinct.
Each state and metacognition must be less than 20 words.

# Format

You will output a JSON object with:
- state[]: array of strings (each string less than 100 words, written in third person)
- metacognition[]: array of strings (each string less than 100 words, written in third person)

The state and metacognition arrays must have the same length (same number of elements).
Each element in the state has a corresponding element in the metacognition array, of same index.

Write in the language of the student's goal and objective.
"""
