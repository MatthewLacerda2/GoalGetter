"""Scaffolding for the background-job tests: the chain (#88), the nightly run
(#89) and the two steps it calls (#90, #91).

Not a pytest plugin - these are helpers the job tests import, like
`fixtures/lessons.at`. They live here because four test modules need the same
three things: every Gemini call replaced, every call recorded in order, and the
session the job opens for itself replaced by the test's.

`calls` is the evidence the job tests are built on. It says not only that a
call happened but *when*, which is the whole point of a chain - a step that
reads what the step before it wrote cannot be allowed to run first - and, just
as often, that no call happened at all, which is what a skip means.
"""

from contextlib import contextmanager
from unittest.mock import patch

from backend.models.resource import Resource, StudyResourceType
from backend.services.gemini.lesson.schema import GeminiLessonQuestionsResponse, LessonQuestionItem
from backend.services.gemini.student_context.schema import (
    ContextVerdict,
    GeminiContextReview,
    GeminiStudentContext,
    GeminiStudentContextResponse,
)

CONTEXT = "backend.services.jobs.steps.context"
QUESTIONS = "backend.services.jobs.steps.questions"
RESOURCES = "backend.services.jobs.steps.resources"
CHAIN = "backend.services.jobs.student_chain"
NIGHTLY = "backend.services.jobs.nightly"

FIRST = GeminiStudentContextResponse(state="Beginner", metacognition="Curious", ai_model="m")

# The answer #90 exists to make cheap: nothing went stale, nothing to add.
NOTHING_CHANGED = GeminiContextReview()


def review(outdated=(), added=()) -> GeminiContextReview:
    """A review naming the indexes it found outdated and the readings to add.

    `outdated` may carry an index that was never shown, or one twice: that is
    the model hallucinating, and the step drops it rather than failing.
    """
    return GeminiContextReview(
        reviewed=[ContextVerdict(index=index, is_outdated=True) for index in outdated],
        new_contexts=[
            GeminiStudentContext(state=state, metacognition=metacognition)
            for state, metacognition in added
        ],
    )


def generated(*correct_indexes) -> GeminiLessonQuestionsResponse:
    """A batch of questions, one per index given. An index outside 0..3 is a
    question the step must drop rather than fail the batch on."""
    return GeminiLessonQuestionsResponse(
        questions=[
            LessonQuestionItem(
                question=f"Q{i}",
                option_a="a",
                option_b="b",
                option_c="c",
                option_d="d",
                correct_option_index=index,
            )
            for i, index in enumerate(correct_indexes)
        ]
    )


GENERATED = generated(0, 3, 4)


def resource(goal_id, link) -> Resource:
    return Resource(
        goal_id=str(goal_id),
        resource_type=StudyResourceType.webpage,
        name="Guide",
        description="A guide",
        language="en",
        link=link,
    )


def recorder(calls: list, name: str, result):
    """A stand-in for one Gemini call: record it, then answer (or blow up)."""

    def record(*args):
        calls.append((name, args))
        if isinstance(result, Exception):
            raise result
        return result

    return record


@contextmanager
def chain_gemini(test_db, calls, questions=GENERATED, found=(), reviewed=NOTHING_CHANGED):
    """The jobs with every Gemini call mocked and every call recorded.

    The session patches are what keep a job on the test's transaction: both the
    chain and the nightly run open one of their own, and neither takes it as an
    argument - they are entry points, not services.
    """
    with (
        patch(CONTEXT + ".gemini_generate_student_context", recorder(calls, "context", FIRST)),
        patch(CONTEXT + ".gemini_review_student_context", recorder(calls, "review", reviewed)),
        patch(QUESTIONS + ".generate_lesson_questions", recorder(calls, "questions", questions)),
        patch(RESOURCES + ".search_resources", recorder(calls, "resources", list(found))),
        patch(RESOURCES + ".validate_resources", side_effect=lambda proposed: proposed),
        patch(CHAIN + ".AsyncSessionLocal", return_value=Session(test_db)),
        patch(NIGHTLY + ".AsyncSessionLocal", return_value=Session(test_db)),
    ):
        yield


class Session:
    """Hands a job the test's session and keeps it open afterwards."""

    def __init__(self, session):
        self.session = session

    async def __aenter__(self):
        return self.session

    async def __aexit__(self, *exc):
        return False
