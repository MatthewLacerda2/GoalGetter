from enum import Enum
from typing import List
from pydantic import BaseModel

class LessonType(Enum):
    SUBJECTIVE = "subjective"
    SINGLE_CORRECT = "single_correct"
    MULTIPLE_CORRECT = "multiple_correct"
    TRUE_FALSE = "true_false"
    MATCHING = "matching"
    ORDERING = "ordering"
