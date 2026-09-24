from dataclasses import dataclass

from backend.models.lesson_answer import LessonAnswer
from backend.models.lesson_question import LessonQuestion


class UnservedQuestionError(ValueError):
    """An answer names a question the lesson did not serve, or names one twice."""


class IncompleteLessonError(ValueError):
    """A question the lesson served came back without an answer.

    Kept apart from UnservedQuestionError because the two say different things
    about the client: one sent an answer we cannot place, the other stopped
    early. The endpoint maps them to 422 and 400 (#86).
    """


@dataclass
class GradedLesson:
    answers: list[LessonAnswer]
    total_seconds: int
    accuracy: float  # 0..100


def grade_lesson(lesson_id, served: list[LessonQuestion], submitted: list) -> GradedLesson:
    """Grade a submission **server-side**, from the stored correct index.

    Nothing the client says about correctness is read: only which choice it
    picked, and how long it took (time is self-reported by nature).

    A submission must name **every** question served, exactly once (#86): the
    student answers each one before the next is shown, so a lesson missing an
    answer is a broken client, not a student who gave up. Accuracy is therefore
    over a complete set.
    """
    by_id = {q.id: q for q in served}
    ids = [a.question_id for a in submitted]
    if len(set(ids)) != len(ids) or not set(ids) <= set(by_id):
        raise UnservedQuestionError(
            "Every answer must name a distinct question served in this lesson"
        )
    if set(ids) != set(by_id):
        raise IncompleteLessonError("Every question this lesson served must be answered")

    answers = [
        LessonAnswer(
            lesson_id=lesson_id,
            question_id=a.question_id,
            selected_option_index=a.choice_index,
            is_correct=a.choice_index == by_id[a.question_id].correct_option_index,
            time_spent=a.seconds_spent,
        )
        for a in submitted
    ]
    correct = sum(a.is_correct for a in answers)
    return GradedLesson(
        answers=answers,
        total_seconds=sum(a.seconds_spent for a in submitted),
        accuracy=round(100 * correct / len(served), 1) if served else 0.0,
    )
