import uuid

from backend.models.question import Question
from backend.repositories.question_repository import QuestionHistory
from backend.services.lessons.selection import select_lesson_questions
from backend.tests.fixtures.lessons import at
from backend.utils.envs import QUESTIONS_PER_LESSON


def entry(name, created=0, answered=None, correct=None):
    """A bank question called `name`, created at minute `created`, whose latest
    answer (if any) came at minute `answered` and was `correct`."""
    question = Question(id=uuid.uuid4(), text=name, created_at=at(created))
    return QuestionHistory(question, at(answered) if answered is not None else None, correct)


def names(bank, size=10):
    return [q.text for q in select_lesson_questions(bank, size)]


def test_wrong_questions_come_most_recent_first():
    bank = [entry("old", answered=1, correct=False), entry("new", answered=9, correct=False)]
    assert names(bank) == ["new", "old"]


def test_never_answered_questions_come_oldest_first():
    bank = [entry("young", created=5), entry("elder", created=1)]
    assert names(bank) == ["elder", "young"]


def test_right_questions_come_least_recently_answered_first():
    bank = [entry("fresh", answered=9, correct=True), entry("stale", answered=1, correct=True)]
    assert names(bank) == ["stale", "fresh"]


def test_mixed_tiers_go_wrong_then_never_then_right():
    bank = [
        entry("right", answered=1, correct=True),
        entry("never", created=0),
        entry("wrong", answered=2, correct=False),
    ]
    assert names(bank) == ["wrong", "never", "right"]


def test_lesson_is_capped_at_its_size():
    bank = [entry(f"q{i}", created=i) for i in range(8)]
    assert names(bank, size=5) == ["q0", "q1", "q2", "q3", "q4"]


def test_a_bank_smaller_than_the_lesson_serves_all_of_it():
    bank = [entry("a", created=0), entry("b", created=1)]
    assert names(bank, size=5) == ["a", "b"]


def test_an_empty_bank_serves_nothing():
    assert select_lesson_questions([], 5) == []


def test_the_default_size_is_the_lessons_own_and_no_callers():
    """#131: the endpoint asks for a lesson; how many that is lives here"""
    bank = [entry(f"q{i}", created=i) for i in range(12)]
    assert len(select_lesson_questions(bank)) == QUESTIONS_PER_LESSON
