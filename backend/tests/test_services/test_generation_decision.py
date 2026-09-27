"""Whether a generation is worth paying for (#135), as arithmetic.

No database, no mock and no clock: the rule is a mean over what the selection
already computed, and the point of these tests is that both of its numbers can
be stated exactly - the line the decision turns on, and the margin the batch is
aimed at.
"""

import uuid
from datetime import UTC, datetime

import pytest

from backend.core.config import settings
from backend.models.question import Question
from backend.services.lessons.generation import GENERATE_ABOVE, decide
from backend.services.lessons.rasch import GUESS, expected_score
from backend.services.lessons.selection import TARGET_SCORE, TOLERANCE_BELOW, Ranked

T0 = datetime(2026, 9, 1, tzinfo=UTC)


def entry(expected: float) -> Ranked:
    """One ranked question the student has this chance of answering right. The
    other four terms order a lesson; only this one decides whether to buy."""
    question = Question(id=uuid.uuid4(), text="Q", created_at=T0)
    return Ranked(question, expected, 0.0, 0.0, 0.0, 0.0, 0.0)


def test_the_line_is_the_hard_edge_of_the_band_the_selection_serves():
    """0.60 twice over: one standard deviation under the target, and the user's
    "se passar de 40% [de erro], nao precisa gerar" said in probability"""
    assert GENERATE_ABOVE == round(TARGET_SCORE - TOLERANCE_BELOW, 2)

    # And par is not 0.5 here: a question at his own rating is answered right
    # five times in eight. So the user's line is a shade *harder* than par -
    # the chance of a question 23 rating points above him.
    assert expected_score(1200, 1200) == GUESS + (1 - GUESS) / 2 == 0.625
    assert expected_score(1200, 1223) == pytest.approx(GENERATE_ABOVE, abs=1e-3)


def test_a_lesson_he_would_mostly_miss_buys_nothing():
    """He is not short of material, he is short of practice"""
    verdict = decide([entry(0.3), entry(0.4), entry(0.5)], answers=settings.PLACEMENT_SIZE)

    assert verdict.generate is False
    assert verdict.predicted == pytest.approx(0.4)
    assert "0.40" in verdict.reason
    assert "under 0.60" in verdict.reason


def test_a_lesson_he_would_walk_through_buys_eight():
    """Too easy is the whole reason to spend a call"""
    verdict = decide([entry(0.9), entry(0.9)], answers=settings.PLACEMENT_SIZE)

    assert (verdict.generate, verdict.placement) == (True, False)
    assert "one step past what he holds" in verdict.reason


def test_the_line_itself_generates():
    """The user's "se passar de" is strict: exactly 40% wrong still buys eight"""
    assert decide([entry(GENERATE_ABOVE)], answers=settings.PLACEMENT_SIZE).generate is True
    assert (
        decide([entry(GENERATE_ABOVE - 0.001)], answers=settings.PLACEMENT_SIZE).generate is False
    )


def test_an_empty_bank_is_the_placement():
    """A goal created minutes ago gets its placement: nothing to be too easy yet"""
    verdict = decide([], answers=0)

    assert (verdict.generate, verdict.placement, verdict.predicted) == (True, True, None)
    assert f"placement: {settings.PLACEMENT_SIZE}" in verdict.reason


def test_until_the_placement_is_answered_nothing_more_is_bought():
    """The user's rule: under 18 answers he has not been measured, so however easy
    the lesson looks, there is nothing to write the next batch from"""
    easy = [entry(0.95), entry(0.95)]

    assert decide(easy, answers=settings.PLACEMENT_SIZE - 1).generate is False
    assert "17 answers, under the 18" in decide(easy, answers=settings.PLACEMENT_SIZE - 1).reason
    assert decide(easy, answers=settings.PLACEMENT_SIZE).generate is True


def test_the_placement_size_is_read_when_deciding(monkeypatch):
    """A patched setting reaches the rule: nothing copied it at import"""
    monkeypatch.setattr(settings, "PLACEMENT_SIZE", 3)
    easy = [entry(0.95), entry(0.95)]

    assert decide(easy, answers=3).generate is True
    assert "2 answers, under the 3" in decide(easy, answers=2).reason
