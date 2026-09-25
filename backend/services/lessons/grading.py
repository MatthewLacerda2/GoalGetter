import uuid
from dataclasses import dataclass

from backend.models.question import Question
from backend.models.student_answer import StudentAnswer


class UnknownQuestionError(ValueError):
    """An answer names a question this goal's bank does not hold, or names one
    twice. Either way the batch cannot be placed, so none of it is stored."""


@dataclass
class GradedLesson:
    lesson_id: uuid.UUID
    answers: list[StudentAnswer]
    total_seconds: int
    accuracy: float  # 0..100


def grade_lesson(bank: list[Question], submitted: list) -> GradedLesson:
    """Grade a submission **server-side**, from the stored right index.

    Nothing the client says about correctness is read: only which choice it
    picked, and how long it took (time is self-reported by nature).

    **The lesson id is minted here**, not received (#131). Nothing was written
    when the questions were served, so the mark can only be made now, and one
    submission is one mark across every answer it carries. It points at no row:
    it says these answers arrived together.

    There is no completeness rule any more. Nothing recorded what was served,
    so "you left one out" is a sentence the backend can no longer say (it was
    #86's 400); what it can still say is that an answer names a question that
    is not this student's, which is what the check below is.
    """
    by_id = {question.id: question for question in bank}
    ids = [answer.question_id for answer in submitted]
    if len(set(ids)) != len(ids) or not set(ids) <= set(by_id):
        raise UnknownQuestionError("Every answer must name a distinct question of this goal's bank")

    lesson_id = uuid.uuid4()
    answers = [
        StudentAnswer(
            lesson_id=lesson_id,
            position=position,
            question_id=item.question_id,
            selected_index=item.choice_index,
            total_seconds=item.seconds_spent,
        )
        for position, item in enumerate(submitted)
    ]
    right = sum(a.selected_index == by_id[a.question_id].right_answer_index for a in answers)
    return GradedLesson(
        lesson_id=lesson_id,
        answers=answers,
        total_seconds=sum(item.seconds_spent for item in submitted),
        accuracy=round(100 * right / len(answers), 1),
    )
