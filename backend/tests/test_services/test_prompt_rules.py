"""The rules every prompt carries (#173), read off the rendered prompt.

No Gemini call: each prompt is rendered from its builder. A rule is pinned by a phrase the prompt has to contain:

- the student's language, **named** (Portuguese and German here, so a prompt
  that always says English fails), where the old prompts guessed it;
- rule 1, his self-report is an *opinion*, and rule 2, the app teaches him
  *as far as he can go*, wherever Gemini reasons about him;
- rule 7, the shortest output: a phrase of each prompt's own, below.
"""

import pytest

from backend.core.language import Language
from backend.schemas.goal import ObjectiveAnswer
from backend.services.gemini.chat.prompt import chat_system_prompt
from backend.services.gemini.chat.schema import StudentContextToChat
from backend.services.gemini.lesson.prompt import get_lesson_generation_prompt
from backend.services.gemini.onboarding.goal_validation_prompt import get_goal_validation_prompt
from backend.services.gemini.onboarding.onboarding import over_word_limit
from backend.services.gemini.onboarding.onboarding_prompts import get_onboarding_questions_prompt
from backend.services.gemini.onboarding.schema import (
    GeminiOnboardingQuestionsResponse,
    OnboardingQuestionItem,
)
from backend.services.gemini.onboarding.study_plan_prompt import get_study_plan_prompt
from backend.services.gemini.resources.prompt import describe_prompt, search_prompt
from backend.services.gemini.student_context.prompt import (
    get_context_review_prompt,
    get_student_context_prompt,
)
from backend.services.gemini.student_context.schema import GeminiStudentContext, StudentGoal

GOALS = [StudentGoal(name="Chess", description="Learn chess openings")]
CONTEXTS = [GeminiStudentContext(state="Knows the moves", metacognition="Impatient")]
ANSWERS = [ObjectiveAnswer(question="How much do you already know?", answer="A lot")]


def resource_prompts(language: Language) -> str:
    """Both of the resource search's prompts (#175), as `search_resources` names
    the language in them."""
    tongue = language.english_name
    return "\n".join(
        [
            search_prompt("Chess", "Learn chess openings", "Knows the moves", [], tongue),
            describe_prompt("Chess", "Knows the moves", "[0] chess.com", tongue),
        ]
    )


# name -> (render the prompt in a language, rules 1 and 2 apply, its brevity phrase)
PROMPTS = {
    "goal-validation": (
        lambda lang: get_goal_validation_prompt("Learn chess", lang),
        False,
        "shortest text that does the job",
    ),
    "onboarding-questions": (
        lambda lang: get_onboarding_questions_prompt("Chess", "Learn chess", lang),
        True,
        "at most 20 words. Shorter is better",
    ),
    "study-plan": (
        lambda lang: get_study_plan_prompt("Learn chess", ANSWERS, lang),
        True,
        "at most 60 words",
    ),
    "tutor": (
        lambda lang: chat_system_prompt("Chess", "Openings", [StudentContextToChat()], lang),
        True,
        "the shortest reply that does the job",
    ),
    "lesson": (
        lambda lang: get_lesson_generation_prompt(
            "Chess", "Openings", "Endgames", 1200, 1232, CONTEXTS, [], [], lang
        ),
        True,
        "as short as it can be",
    ),
    "first-context": (
        lambda lang: get_student_context_prompt(GOALS, "I want chess", None, lang),
        True,
        "in as few words as that takes",
    ),
    "context-review": (
        lambda lang: get_context_review_prompt(GOALS, CONTEXTS, [], [], None, lang),
        True,
        "as short as it can be",
    ),
    "resource-search": (resource_prompts, True, "Nothing else: no URLs, no introduction"),
}


@pytest.mark.parametrize("name", PROMPTS)
@pytest.mark.parametrize(
    "language, named", [(Language.PORTUGUESE, "Portuguese"), (Language.GERMAN, "German")]
)
def test_every_prompt_names_the_students_language(name, language, named):
    render, _, _ = PROMPTS[name]
    prompt = render(language)

    assert f"in {named}" in prompt
    assert "same language" not in prompt and "user's language" not in prompt


@pytest.mark.parametrize("name", PROMPTS)
def test_every_prompt_asks_for_the_shortest_output(name):
    render, _, brevity = PROMPTS[name]

    assert brevity in " ".join(render(Language.ENGLISH).split())


@pytest.mark.parametrize("name", [name for name, (_, about, _) in PROMPTS.items() if about])
def test_his_self_report_is_an_opinion_and_his_ambition_no_ceiling(name):
    render, _, _ = PROMPTS[name]
    prompt = " ".join(render(Language.ENGLISH).split())

    assert "opinion" in prompt
    assert "as far as he can go" in prompt


def test_the_goal_validation_does_not_take_a_ceiling_as_the_goal():
    assert "as far as he can go" in get_goal_validation_prompt("Only the basics", Language.ENGLISH)


def test_onboarding_asks_for_eight_short_questions_and_no_self_rating():
    prompt = get_onboarding_questions_prompt("Chess", "Learn chess", Language.ENGLISH)

    assert "exactly 8 multiple-choice" in prompt
    assert "at most 20 words" in prompt
    assert "Do not ask the student to rate his own level" in prompt
    assert "familiarity/experience level" not in prompt


def test_the_study_plan_is_brief_as_a_number():
    prompt = get_study_plan_prompt("Learn chess", ANSWERS, Language.ENGLISH)

    assert "at most 60 words" in prompt
    assert "400 lines" not in prompt


def test_a_question_over_twenty_words_is_reported_not_refused():
    long = " ".join(["word"] * 21)
    generated = GeminiOnboardingQuestionsResponse(
        questions=[
            OnboardingQuestionItem(
                question="Short?", option_a=long, option_b="b", option_c="c", option_d="d"
            )
        ]
    )

    assert over_word_limit(generated) == [long]
