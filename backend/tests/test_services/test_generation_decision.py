"""Whether a generation is worth paying for (#135), as arithmetic.

No database, no mock and no clock: the rule is a mean over what the selection
already computed, and the point of these tests is that both of its numbers can
be stated exactly - the line the decision turns on, and the margin the batch is
aimed at.
"""

import uuid
from datetime import UTC, datetime

import pytest

from backend.models.question import Question
from backend.services.lessons.generation import (
    GENERATE_ABOVE,
    GENERATION_MARGIN,
    decide,
)
from backend.services.lessons.rasch import GUESS, K_MIN, SCALE, expected_score
from backend.services.lessons.selection import TARGET_SCORE, TOLERANCE_BELOW, Ranked
from backend.utils.envs import QUESTIONS_PER_GENERATION

T0 = datetime(2026, 9, 1, tzinfo=UTC)


def entry(expected: float) -> Ranked:
    """One ranked question the student has this chance of answering right. The
    other four terms order a lesson; only this one decides whether to buy."""
    question = Question(id=uuid.uuid4(), text="Q", created_at=T0)
    return Ranked(question, expected, 0.0, 0.0, 0.0, 0.0, 0.0)


def test_the_line_is_the_hard_edge_of_the_band_the_selection_serves():
    """0.60 twice over: one standard deviation under the target, and the user's
    "se passar de 40% [de erro], nao precisa gerar" said in probability"""
    assert GENERATE_ABOVE == 0.60
    assert GENERATE_ABOVE == round(TARGET_SCORE - TOLERANCE_BELOW, 2)
    # 40% wrong is 60% right, and `E` predicts exactly that - the lucky guesses
    # included, because the 0.25 floor is what puts them in it.
    assert GENERATE_ABOVE == 1 - 0.40

    # And par is not 0.5 here: a question at his own rating is answered right
    # five times in eight. So the user's line is a shade *harder* than par -
    # the chance of a question 23 rating points above him.
    assert expected_score(1200, 1200) == GUESS + (1 - GUESS) / 2 == 0.625
    assert expected_score(1200, 1223) == pytest.approx(GENERATE_ABOVE, abs=1e-3)


def test_the_margin_is_what_the_batch_itself_pays_him():
    """Eight answers at the accuracy this gate fires at, at a settled K"""
    assert GENERATION_MARGIN == 32
    assert GENERATION_MARGIN == round(QUESTIONS_PER_GENERATION * K_MIN * (1 - GENERATE_ABOVE))
    # Which is just past the hard edge of what the selection would serve him:
    # 23 points. Aiming in the hundreds would buy questions it then refuses.
    edge = SCALE * 0.05799
    assert edge < GENERATION_MARGIN < 3 * edge


def test_a_lesson_he_would_mostly_miss_buys_nothing():
    """He is not short of material, he is short of practice"""
    verdict = decide([entry(0.3), entry(0.4), entry(0.5)], rating=1200)

    assert verdict.generate is False
    assert verdict.predicted == pytest.approx(0.4)
    assert "0.40" in verdict.reason and "under 0.60" in verdict.reason


def test_a_lesson_he_would_walk_through_buys_eight_above_him():
    """Too easy is the whole reason to spend a call, and it is spent on where
    he is going, not on where he is"""
    verdict = decide([entry(0.9), entry(0.9)], rating=1400)

    assert verdict.generate is True
    assert verdict.target == 1400 + GENERATION_MARGIN == 1432
    assert "difficulty 1432" in verdict.reason


def test_the_line_itself_generates():
    """The user's "se passar de" is strict: exactly 40% wrong still buys eight"""
    assert decide([entry(GENERATE_ABOVE)], rating=1200).generate is True
    assert decide([entry(GENERATE_ABOVE - 0.001)], rating=1200).generate is False


def test_an_empty_bank_is_a_goal_created_minutes_ago():
    """The one branch with no mean to take: there is nothing to be too easy yet"""
    verdict = decide([], rating=1200)

    assert (verdict.generate, verdict.predicted) == (True, None)
    assert "first batch" in verdict.reason
