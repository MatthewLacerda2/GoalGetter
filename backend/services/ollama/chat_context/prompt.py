from typing import List, Optional
from backend.models.chat_message import ChatMessage

def format_chat_messages(messages: List[ChatMessage]) -> str:
    """Format chat messages for the prompt"""
    if not messages:
        return "No chat messages available."
    
    message_parts = []
    for message in messages:
        role = "user" if message.student_id == message.sender_id else "assistant"
        message_parts.append(f"{role}: {message.message}")
    
    return "\n".join(message_parts)

def get_chat_context_prompt(
    goal_name: str,
    goal_description: str,
    objective_name: str,
    objective_description: str,
    messages: List[ChatMessage],
    student_context: Optional[List[str]] = None
) -> str:
    """Generate prompt for chat context generation"""
    formatted_messages = format_chat_messages(messages)
    context_list: str = ("Here is some context about the student:\n" + "\n".join([f"- {context}." for context in student_context])) if student_context else ""
    
    return f"""
## Context

You are an experienced Tutor analyzing chat conversations to extract insights about the student's learning state and cognitive patterns.

The student has a goal: '{goal_name}' - {goal_description}
Current objective: '{objective_name}' - {objective_description}

{context_list}

## Task

Analyze the chat conversation between the student and the chatbot to generate:

- State: student's current state/knowledge based on their messages and interactions
- Metacognition: student's cognitive awareness and learning patterns observed in the conversation

## Guidelines

- Both arrays must have the same length (same number of elements)
- You can choose to send a state text but keep its corresponding metacognition empty (empty string), and vice-versa
- You can elect not to say anything about state and metacognition (send empty arrays)
- Only include state/metacognition information that is complementary to creating a database of what we know about the user or the user's cognitive behavior
- All state and metacognition texts must be written in third person (e.g., "The student demonstrates..." not "You demonstrate...")
- Focus on factual, observable insights about the student's learning state and cognitive patterns derived from the conversation
- Consider the flow of conversation, questions asked, responses given, and learning patterns revealed
- Only write student context which is new information. If you have nothing to add, just send an empty array
- Focus on sending high density-value data, not high-volume

Here is the chat conversation:
{formatted_messages}

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
