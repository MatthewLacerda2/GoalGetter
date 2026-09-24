from backend.models.lesson_question import LessonQuestion
from backend.repositories.lesson_question_repository import QuestionHistory


def select_lesson_questions(bank: list[QuestionHistory], size: int) -> list[LessonQuestion]:
    """Pick a lesson's questions from the goal's bank.

    The rule (issue #55): the lesson focuses on the questions the student most
    recently got wrong. Take, in this order, until the lesson is full:
      1. questions whose **latest** answer was wrong, most recent first;
      2. questions never answered, oldest first;
      3. everything else, least recently answered first.

    Ties fall back to the question's creation time, then its id, so the same
    bank always yields the same lesson. Question embeddings (reuse across
    students) are not used yet.

    `size` is a **cap, not a floor** (#86): a bank shorter than a full lesson
    serves what it has. The student whose bank is empty is the one who has just
    created a goal, and the endpoint already tells them so with a 409; a bank
    that is short but not empty means last night's generation came back thin,
    and refusing would turn one bad night at Gemini into a lost day of study.
    The bank only grows - questions are never deleted, and a generation tops it
    up to two lessons - so a short lesson repairs itself.
    """

    def created(entry: QuestionHistory):
        return (entry.question.created_at, str(entry.question.id))

    wrong = [e for e in bank if e.last_was_correct is False]
    never = [e for e in bank if e.last_answered_at is None]
    right = [e for e in bank if e.last_was_correct is True]

    wrong.sort(key=created)
    wrong.sort(key=lambda e: e.last_answered_at, reverse=True)
    never.sort(key=created)
    right.sort(key=created)
    right.sort(key=lambda e: e.last_answered_at)

    return [e.question for e in (wrong + never + right)[:size]]
