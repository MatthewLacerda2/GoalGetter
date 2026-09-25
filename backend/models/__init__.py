from backend.models.base import Base
from backend.models.chat_message import ChatMessage
from backend.models.frontier import Frontier
from backend.models.goal import Goal
from backend.models.onboarding_question import OnboardingQuestion
from backend.models.question import Question
from backend.models.refresh_token import RefreshToken
from backend.models.resource import Resource
from backend.models.student import Student
from backend.models.student_answer import StudentAnswer
from backend.models.student_context import StudentContext

# Importing this package registers every model on Base.metadata; `__all__`
# says so out loud, so the imports read as the exports they are.
__all__ = [
    "Base",
    "ChatMessage",
    "Frontier",
    "Goal",
    "OnboardingQuestion",
    "Question",
    "RefreshToken",
    "Resource",
    "Student",
    "StudentAnswer",
    "StudentContext",
]
