import pytest

from backend.core.language import Language
from backend.services.language.detection import detect_language


@pytest.mark.parametrize(
    ("text", "expected"),
    [
        ("I want to learn chess", Language.ENGLISH),
        ("How do the pieces move in the opening?", Language.ENGLISH),
        ("Quero aprender xadrez", Language.PORTUGUESE),
        ("Eu quero entender como funciona a bolsa de valores", Language.PORTUGUESE),
        ("Quiero aprender a tocar la guitarra", Language.SPANISH),
        ("Me gustaría entender cómo funciona el mercado", Language.SPANISH),
        ("Je veux apprendre à jouer aux échecs", Language.FRENCH),
        ("J'aimerais comprendre comment fonctionne la bourse", Language.FRENCH),
        ("Ich möchte Schach lernen", Language.GERMAN),
        ("Ich will verstehen, wie die Börse funktioniert", Language.GERMAN),
    ],
)
def test_a_real_sentence_is_classified_by_its_common_words(text, expected):
    assert detect_language(text) == expected


@pytest.mark.parametrize(
    "text",
    [
        "Chess",  # a goal's name says nothing about who wrote it
        "Python",
        "Xadrez",  # a Portuguese word, but not a common one
        "",
        "   ",
        "42 + 7",
        "de",  # Portuguese, Spanish and French all claim it: a tie
        "que a",  # the same three, tied again
    ],
)
def test_it_says_none_when_it_cannot_tell(text):
    assert detect_language(text) is None
