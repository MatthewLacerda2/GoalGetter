from backend.models.base import Base
from backend.models.chat_message import ChatMessage
from backend.models.goal import Goal
from backend.models.lesson import Lesson
from backend.models.lesson_answer import LessonAnswer
from backend.models.lesson_question import LessonQuestion
from backend.models.microlearning_content import MicrolearningContent
from backend.models.onboarding_question import OnboardingQuestion
from backend.models.refresh_token import RefreshToken
from backend.models.resource import Resource
from backend.models.student import Student
from backend.models.student_context import StudentContext

# Importing this package registers every model on Base.metadata; `__all__`
# says so out loud, so the imports read as the exports they are.
__all__ = [
    "Base",
    "ChatMessage",
    "Goal",
    "Lesson",
    "LessonAnswer",
    "LessonQuestion",
    "MicrolearningContent",
    "OnboardingQuestion",
    "RefreshToken",
    "Resource",
    "Student",
    "StudentContext",
]
