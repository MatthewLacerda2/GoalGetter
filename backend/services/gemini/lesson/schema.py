from pydantic import BaseModel, Field


class AnsweredQuestion(BaseModel):
    """One question the student has already answered, as the generator is shown
    it (#135). An input shape, like `GeminiStudentContext` - the two classes
    below are what Gemini returns.

    **The prompt carries the questions themselves, never statistics about
    them.** A model reading twenty real questions learns more about a student
    than one reading "62% accuracy", and the option he chose is the half that
    carries the belief: a wrong answer says little, and *which* wrong answer
    says what he thinks is true. Aggregate numbers decide *whether* to generate
    (services/lessons/generation.py); they are not what is generated from.
    """

    question: str = Field(description="The question as the student was asked it")
    chosen: str = Field(description="The option the student picked")
    correct: str = Field(description="The option that was right")


class LessonQuestionItem(BaseModel):
    question: str = Field(description="The text of the study question")
    option_a: str = Field(description="Option A")
    option_b: str = Field(description="Option B")
    option_c: str = Field(description="Option C")
    option_d: str = Field(description="Option D")
    correct_option_index: int = Field(
        description="The index of the correct option (0 for A, 1 for B, 2 for C, 3 for D)"
    )


class GeminiLessonQuestionsResponse(BaseModel):
    questions: list[LessonQuestionItem] = Field(
        description="List of custom study questions generated for the student"
    )
