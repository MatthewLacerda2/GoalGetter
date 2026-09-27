"""What the rating must do on every input, not only on the ones written down (#207).

`test_rasch.py` pins the curve to numbers. These state what makes it a curve
worth having - bounded by the guess floor and certainty, monotonic in both
arguments, blind to where the scale starts - and what makes `replay` a function
of the history: the order the bank arrives in, ties included, changes nothing.
"""

import math
from datetime import UTC, datetime, timedelta

import pytest
from hypothesis import assume, given
from hypothesis import strategies as st

from backend.models.question import Question
from backend.repositories.student_answer_repository import AnswerRecord
from backend.services.lessons.rasch import (
    GUESS,
    SCALE,
    SKILL_CLAMP,
    difficulty,
    expected_score,
    replay,
)

T0 = datetime(2026, 9, 1, tzinfo=UTC)

# Wider than any goal gets: a rating starts at 1200 and moves tens of points a lesson.
ratings = st.floats(min_value=-4000, max_value=8000)
# Few distinct minutes, so questions born at the same moment are common.
births = st.integers(min_value=0, max_value=3)


@given(ratings, ratings)
def test_the_chance_of_a_right_answer_is_never_under_the_guess_or_over_certainty(rating, hard):
    assert GUESS <= expected_score(rating, hard) <= 1


@given(ratings, ratings, ratings)
def test_a_stronger_student_or_an_easier_question_is_never_less_likely_right(rating, hard, other):
    low, high = sorted((rating, other))

    assert expected_score(low, hard) <= expected_score(high, hard)
    assert expected_score(rating, high) <= expected_score(rating, low)


@given(ratings, ratings, st.floats(min_value=-2000, max_value=2000))
def test_only_the_gap_between_student_and_question_matters(rating, hard, shift):
    assert expected_score(rating + shift, hard + shift) == pytest.approx(
        expected_score(rating, hard), abs=1e-9
    )


@given(ratings, st.integers(min_value=0, max_value=200), st.data())
def test_more_right_answers_never_make_a_question_harder(anchor, answered, data):
    right = data.draw(st.integers(min_value=0, max_value=answered))
    fewer = data.draw(st.integers(min_value=0, max_value=right))
    reach = SCALE * math.log10(SKILL_CLAMP / (1 - SKILL_CLAMP))

    assert difficulty(anchor, answered, right) <= difficulty(anchor, answered, fewer)
    assert abs(difficulty(anchor, answered, right) - anchor) <= reach + 1e-6


@st.composite
def histories(draw):
    """A bank born over a few minutes, and answers to it in time order - the
    order the repository hands them over in."""
    born = st.lists(st.tuples(births, st.uuids()), min_size=1, max_size=6, unique_by=lambda b: b[1])
    bank = [
        Question(id=key, created_at=T0 + timedelta(minutes=minute)) for minute, key in draw(born)
    ]
    picks = draw(st.lists(st.tuples(st.sampled_from(bank), births, st.booleans()), max_size=20))
    answers = [
        AnswerRecord(question.id, T0 + timedelta(minutes=minute), right)
        for question, minute, right in sorted(picks, key=lambda pick: pick[1])
    ]
    return bank, answers


@given(histories(), st.randoms(use_true_random=False))
def test_the_order_the_bank_arrives_in_changes_nothing(history, rng):
    """Questions born at the same moment included: the walk sorts them itself"""
    bank, answers = history
    shuffled = list(bank)
    rng.shuffle(shuffled)

    assert replay(shuffled, answers) == replay(bank, answers)


@given(histories())
def test_the_last_answer_right_never_leaves_him_below_the_same_answer_wrong(history):
    bank, answers = history
    assume(answers)
    *earlier, last = answers
    right = AnswerRecord(last.question_id, last.answered_at, True)
    wrong = AnswerRecord(last.question_id, last.answered_at, False)

    assert replay(bank, [*earlier, right]).rating >= replay(bank, [*earlier, wrong]).rating
