"""How many questions two minutes is (#134).

The count was never decided; two minutes was. These pin what that turns into
for real paces, and that the floor of six is what a student we know nothing
about gets.
"""

from statistics import median

from hypothesis import assume, given
from hypothesis import strategies as st

from backend.services.lessons.pacing import (
    LESSON_SECONDS,
    MAX_QUESTIONS,
    MIN_QUESTIONS,
    PACE_WINDOW,
    lesson_size,
)

paces = st.lists(st.one_of(st.none(), st.integers(min_value=-5, max_value=600)), max_size=40)


@given(paces)
def test_a_lesson_is_never_under_the_floor_or_over_the_cap(seconds):
    assert MIN_QUESTIONS <= lesson_size(seconds) <= MAX_QUESTIONS


@given(st.lists(st.integers(min_value=8, max_value=24), min_size=1, max_size=40))
def test_between_the_bounds_the_lesson_is_two_minutes_of_his_pace(seconds):
    """Half a question either way: the count is rounded, the two minutes are not.
    Paces of 8-24 s straddle the band where neither bound decides (10-20 s)."""
    size = lesson_size(seconds)
    pace = median(seconds[:PACE_WINDOW])
    assume(MIN_QUESTIONS < size < MAX_QUESTIONS)

    assert abs(size * pace - LESSON_SECONDS) <= pace / 2


@given(paces, paces)
def test_only_the_last_window_of_answers_sets_the_pace(recent, older):
    """Newest first: what came before the window is not his pace any more"""
    window = (recent + [30] * PACE_WINDOW)[:PACE_WINDOW]

    assert lesson_size(window + older) == lesson_size(window)


def test_a_student_with_no_timed_answers_gets_the_floor_not_a_guess():
    """His first lesson ever, and a client that sent no durations"""
    assert lesson_size([]) == MIN_QUESTIONS
    assert lesson_size([None, None]) == MIN_QUESTIONS
    assert lesson_size([0, 0, 0]) == MIN_QUESTIONS


def test_two_paces_fill_the_same_two_minutes_with_different_counts():
    """The whole point: the count is his, the two minutes are the product's"""
    deliberate = lesson_size([24] * 8)
    quick = lesson_size([11] * 8)

    assert deliberate == 6
    assert quick == 11
    # both about two minutes
    assert deliberate * 24 == 144
    assert quick * 11 == 121
    assert deliberate >= MIN_QUESTIONS
    assert quick >= MIN_QUESTIONS


def test_nobody_gets_fewer_than_six_or_more_than_twelve():
    """A student answering in three seconds is not handed forty questions"""
    assert lesson_size([300] * 8) == MIN_QUESTIONS
    assert lesson_size([3] * 8) == MAX_QUESTIONS
    assert lesson_size([1] * 8) == MAX_QUESTIONS


def test_one_interrupted_question_does_not_resize_the_next_three_lessons():
    """The phone on the table is not thinking time, and the median ignores it"""
    steady = [8] * 7

    assert lesson_size([*steady, 3600]) == MAX_QUESTIONS
    assert lesson_size([*steady, 8]) == MAX_QUESTIONS
    # A student who is genuinely slow reads the same either way: no second mode.
    assert lesson_size([30] * 8) == lesson_size([30] * 7 + [31]) == MIN_QUESTIONS


def test_only_the_last_three_lessons_count():
    """Newest first, so a pace he left behind stops resizing today's lesson"""
    now_slow = [40] * PACE_WINDOW + [5] * 100
    now_quick = [5] * PACE_WINDOW + [40] * 100

    assert lesson_size(now_slow) == MIN_QUESTIONS
    assert lesson_size(now_quick) == MAX_QUESTIONS
