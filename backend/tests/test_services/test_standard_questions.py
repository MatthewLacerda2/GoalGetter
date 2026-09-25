"""The standard onboarding questions as data (#132).

They are written by us, not generated, so what there is to check is that they
fit the table and that the keys the client answers with are unambiguous. The
other half of the seam - that every key has a sentence in the five locales - is
`frontend/test/features/onboarding/standard_questions_test.dart`, because that
is where the translations live.
"""

from backend.services.onboarding.standard_questions import STANDARD_QUESTIONS, SYSTEM_AUTHOR


def test_every_question_has_exactly_four_options():
    """The shape `onboarding_questions` stores: four options and the one picked.
    An age is asked as four bands rather than as a number for that reason."""
    for question in STANDARD_QUESTIONS:
        assert len(question.options) == 4


def test_no_key_is_ambiguous():
    """A key is what crosses the wire, so a repeat would store the wrong answer"""
    keys = [question.key for question in STANDARD_QUESTIONS]
    assert len(set(keys)) == len(keys)
    for question in STANDARD_QUESTIONS:
        option_keys = [option.key for option in question.options]
        assert len(set(option_keys)) == 4


def test_every_question_and_option_carries_text_for_the_prompt():
    """The database keeps English whatever locale the student answered in: it is
    a prompt that reads these rows, not a screen"""
    for question in STANDARD_QUESTIONS:
        assert question.text.strip()
        for option in question.options:
            assert option.text.strip()


def test_the_author_of_a_question_nobody_generated():
    """`ai_model` is never null and never a model here"""
    assert SYSTEM_AUTHOR == "system"
