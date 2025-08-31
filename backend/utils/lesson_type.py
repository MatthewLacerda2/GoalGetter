from enum import Enum

class LessonType(Enum):
    MULTIPLE_CHOICE = "multiple_choice"
    TRUE_FALSE = "true_false"
    MATCHING = "matching"
    ORDERING = "ordering"
    SUBJECTIVE = "subjective"