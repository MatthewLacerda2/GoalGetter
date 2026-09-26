"""Which language a prompt names (#173): his choice, else what he typed, else English."""

from backend.core.language import Language
from backend.services.gemini.output_language import output_language


def test_his_choice_wins_over_what_he_typed():
    assert output_language("de", "Eu quero aprender xadrez") == Language.GERMAN


def test_without_a_choice_the_language_of_what_he_typed():
    assert output_language(None, "Eu quero aprender xadrez") == Language.PORTUGUESE


def test_with_nothing_to_go_on_english():
    assert output_language(None, "Chess") == Language.ENGLISH
    assert output_language(None) == Language.ENGLISH


def test_a_code_the_app_does_not_speak_is_no_choice():
    assert output_language("xx", "Quiero aprender ajedrez") == Language.SPANISH
