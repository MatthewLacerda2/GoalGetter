# lint: data-file
"""The standard onboarding questions: the four we already know to ask (#132).

They are asked while the student chain generates his context and his first
batch of questions, so the wait after the study plan is time he spends telling
us about himself rather than watching a spinner. Nothing blocks on them: the
batch is already in flight when the first one is drawn, and a student who skips
through goes straight to his lesson.

**What lives here and what lives in the ARB files.** A question is a `key`, the
English sentence the *database* stores, and four options that are the same
three things each. The student never reads a word of this file: the frontend is
handed the keys by `POST /goals` and draws
`lib/features/onboarding/presentation/standard_question_text.dart`, which maps
each key to an ARB entry in the five locales. The key is what crosses the wire
in both directions; the text here is what Gemini reads, so every student's
onboarding reaches a prompt in one language whatever language he answered in.

**Four options, always - an age included.** `onboarding_questions` stores four
options and the index of the one picked, and these questions are written to fit
that rather than the other way round: the age question asks for a band, not a
number, which is all a prompt can use anyway. A free-text question would have
to be stored the way the goal prompt is (the text in `option_a`, no index), and
nothing here needs one.

Adding a question means adding it here *and* adding its key and its options'
keys to the five ARB files; `make front-lint` fails a key a locale is missing,
and `backend/tests/test_services/test_standard_questions.py` fails a key shape
this file cannot serve.
"""

from dataclasses import dataclass

# What `onboarding_questions.ai_model` holds for a row no model wrote: these
# four questions, and the "What do you want to learn?" row that carries the
# student's own words. Gemini-written rows carry the model that wrote them, so
# one read of a student's onboarding tells the two apart (#132).
SYSTEM_AUTHOR = "system"


@dataclass(frozen=True)
class StandardOption:
    """One option: the key the client answers with, and the text stored."""

    key: str
    text: str


@dataclass(frozen=True)
class StandardQuestion:
    """One standard question and its exactly four options."""

    key: str
    text: str
    options: tuple[StandardOption, ...]


STANDARD_QUESTIONS: tuple[StandardQuestion, ...] = (
    StandardQuestion(
        key="age",
        text="How old are you?",
        options=(
            StandardOption("under18", "Under 18"),
            StandardOption("18to24", "18 to 24"),
            StandardOption("25to39", "25 to 39"),
            StandardOption("40plus", "40 or older"),
        ),
    ),
    StandardQuestion(
        key="purpose",
        text="What are you learning this for?",
        options=(
            StandardOption("school", "School or university"),
            StandardOption("work", "My work or my career"),
            StandardOption("project", "Something I am building"),
            StandardOption("curiosity", "Curiosity, nothing more"),
        ),
    ),
    StandardQuestion(
        key="level",
        text="How much do you already know about it?",
        options=(
            StandardOption("nothing", "Nothing at all"),
            StandardOption("little", "A little, here and there"),
            StandardOption("enough", "Enough to get by"),
            StandardOption("deep", "I know it well and want to go deeper"),
        ),
    ),
    StandardQuestion(
        key="time",
        text="How much time can you give it on a normal day?",
        options=(
            StandardOption("minutes", "A few minutes"),
            StandardOption("quarter", "About fifteen minutes"),
            StandardOption("half", "About half an hour"),
            StandardOption("hour", "An hour or more"),
        ),
    ),
)
