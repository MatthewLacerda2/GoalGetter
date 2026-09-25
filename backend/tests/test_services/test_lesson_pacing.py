"""How many questions two minutes is (#134).

The count was never decided; two minutes was. These pin what that turns into
for real paces, and that the floor of six is what a student we know nothing
about gets.
"""

from backend.services.lessons.pacing import (
    LESSON_SECONDS,
    MAX_QUESTIONS,
    MIN_QUESTIONS,
    PACE_WINDOW,
    lesson_size,
)


def test_two_minutes_is_what_was_decided_and_six_is_the_floor():
    assert LESSON_SECONDS == 120
    assert MIN_QUESTIONS == 6
    assert MAX_QUESTIONS == 2 * MIN_QUESTIONS


def test_a_student_with_no_timed_answers_gets_the_floor_not_a_guess():
    """His first lesson ever, and a client that sent no durations"""
    assert lesson_size([]) == MIN_QUESTIONS
    assert lesson_size([None, None]) == MIN_QUESTIONS
    assert lesson_size([0, 0, 0]) == MIN_QUESTIONS


def test_two_paces_fill_the_same_two_minutes_with_different_counts():
    """The whole point: the count is his, the two minutes are the product's"""
    deliberate = lesson_size([24] * 8)
    quick = lesson_size([11] * 8)

    assert deliberate == 6 and quick == 11
    assert deliberate * 24 == 144 and quick * 11 == 121  # both about two minutes
    assert deliberate >= MIN_QUESTIONS and quick >= MIN_QUESTIONS


def test_nobody_gets_fewer_than_six_or_more_than_twelve():
    """A student answering in three seconds is not handed forty questions"""
    assert lesson_size([300] * 8) == MIN_QUESTIONS
    assert lesson_size([3] * 8) == MAX_QUESTIONS
    assert lesson_size([1] * 8) == MAX_QUESTIONS


def test_one_interrupted_question_does_not_resize_the_next_three_lessons():
    """The phone on the table is not thinking time, and the median ignores it"""
    steady = [8] * 7

    assert lesson_size(steady + [3600]) == MAX_QUESTIONS
    assert lesson_size(steady + [8]) == MAX_QUESTIONS
    # A student who is genuinely slow reads the same either way: no second mode.
    assert lesson_size([30] * 8) == lesson_size([30] * 7 + [31]) == MIN_QUESTIONS


def test_only_the_last_three_lessons_count():
    """Newest first, so a pace he left behind stops resizing today's lesson"""
    now_slow = [40] * PACE_WINDOW + [5] * 100
    now_quick = [5] * PACE_WINDOW + [40] * 100

    assert lesson_size(now_slow) == MIN_QUESTIONS
    assert lesson_size(now_quick) == MAX_QUESTIONS
