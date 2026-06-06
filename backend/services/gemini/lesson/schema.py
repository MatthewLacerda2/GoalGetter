from pydantic import BaseModel, Field

class LessonQuestionItem(BaseModel):
    question: str = Field(description="The text of the study question")
    option_a: str = Field(description="Option A")
    option_b: str = Field(description="Option B")
    option_c: str = Field(description="Option C")
    option_d: str = Field(description="Option D")
    correct_option_index: int = Field(description="The index of the correct option (0 for A, 1 for B, 2 for C, 3 for D)")

class GeminiLessonQuestionsResponse(BaseModel):
    questions: list[LessonQuestionItem] = Field(description="List of custom study questions generated for the student")
