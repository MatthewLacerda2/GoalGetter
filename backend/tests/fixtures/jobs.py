"""Scaffolding for the background-job tests: the chain, the nightly run
and the steps they call.

Not a pytest plugin - these are helpers the job tests import, like
`fixtures/lessons.at`. They live here because four test modules need the same
three things: every Gemini call replaced, every call recorded in order, and the
session the job opens for itself replaced by the test's.

`calls` is the evidence the job tests are built on. It says not only that a
call happened but *when*, which is the whole point of a chain - a step that
reads what the step before it wrote cannot be allowed to run first - and, just
as often, that no call happened at all, which is what a skip means.
"""

import inspect
import pkgutil
from contextlib import contextmanager
from unittest.mock import AsyncMock, patch

import numpy as np

from backend.core.vectors import NUM_DIMENSIONS
from backend.models.resource import Resource, StudyResourceType
from backend.services.gemini.lesson.schema import GeminiLessonQuestionsResponse, LessonQuestionItem
from backend.services.gemini.resources.search_resources import FoundPage, ResourceSearch
from backend.services.gemini.student_context.schema import (
    ContextVerdict,
    FrontierMove,
    GeminiContextReview,
    GeminiStudentContext,
    GeminiStudentContextResponse,
)

CONTEXT = "backend.services.jobs.steps.context"
QUESTIONS = "backend.services.jobs.steps.questions"
RESOURCES = "backend.services.jobs.steps.resources"
FRONTIER = "backend.services.jobs.steps.frontier"
CHAIN = "backend.services.jobs.student_chain"
NIGHTLY = "backend.services.jobs.nightly"

FIRST = GeminiStudentContextResponse(state="Beginner", metacognition="Curious", ai_model="m")

# The answer the context review exists to make cheap: nothing went stale, nothing to add.
NOTHING_CHANGED = GeminiContextReview()


def review(outdated=(), added=(), moved=()) -> GeminiContextReview:
    """A review naming the indexes it found outdated, the readings to add and
    the goals whose frontier has moved on.

    `outdated` and `moved` may carry an index that was never shown, or one
    twice: that is the model hallucinating, and the step drops it rather than
    failing.
    """
    return GeminiContextReview(
        reviewed=[ContextVerdict(index=index, is_outdated=True) for index in outdated],
        new_contexts=[
            GeminiStudentContext(state=state, metacognition=metacognition)
            for state, metacognition in added
        ],
        frontiers=[FrontierMove(index=index, definition=text) for index, text in moved],
    )


def axis(index: int) -> np.ndarray:
    """A stand-in embedding pointing along one axis. Two of them are either the
    same direction (cosine 1) or perpendicular (cosine 0), so a test says "this
    frontier is the same subject" or "this one is a different one" with no
    arithmetic of its own."""
    vector = np.zeros(NUM_DIMENSIONS, dtype=np.float32)
    vector[index] = 1.0
    return vector


# The goal's own description, and the two things a proposed frontier can be.
SUBJECT = axis(0)
ALONGSIDE = axis(0)
ELSEWHERE = axis(1)


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


def page(link) -> FoundPage:
    """A page the resource search found, before it is a row."""
    return FoundPage("webpage", "Guide", "A guide", "en", link)


def resource(goal_id, link) -> Resource:
    return Resource(
        goal_id=str(goal_id),
        resource_type=StudyResourceType.webpage,
        name="Guide",
        description="A guide",
        language="en",
        link=link,
    )


def recorder(calls: list, name: str, result, like):
    """A stand-in for one Gemini use case: record it, then answer (or blow up).

    The arguments are recorded in the order `like` - the use case it stands in
    for - declares them, however the caller passed them: the jobs pass them by
    name, and the tests read them by position."""
    signature = inspect.signature(like)

    async def record(*args, **kwargs):
        bound = signature.bind(*args, **kwargs)
        bound.apply_defaults()
        calls.append((name, tuple(bound.arguments.values())))
        if isinstance(result, Exception):
            raise result
        return result

    return record


def stand_in(target: str, calls: list, name: str, result):
    """Patch the use case at `target` with a `recorder` shaped like it."""
    return patch(target, recorder(calls, name, result, pkgutil.resolve_name(target)))


@contextmanager
def chain_gemini(
    test_db, calls, questions=GENERATED, found=(), reviewed=NOTHING_CHANGED, embedding=ALONGSIDE
):
    """The jobs with every Gemini call mocked and every call recorded.

    The session patches are what keep a job on the test's transaction: both the
    chain and the nightly run open one of their own, and neither takes it as an
    argument - they are entry points, not services.
    """
    with (
        stand_in(CONTEXT + ".gemini_generate_student_context", calls, "context", FIRST),
        stand_in(CONTEXT + ".gemini_review_student_context", calls, "review", reviewed),
        stand_in(QUESTIONS + ".generate_lesson_questions", calls, "questions", questions),
        stand_in(QUESTIONS + ".generate_placement_questions", calls, "placement", questions),
        stand_in(FRONTIER + ".get_gemini_embeddings", calls, "embedding", embedding),
        stand_in(
            RESOURCES + ".search_resources",
            calls,
            "resources",
            ResourceSearch(list(found), "a query"),
        ),
        patch(RESOURCES + ".search_videos", AsyncMock(return_value=[])),
        patch(
            RESOURCES + ".validate_resources",
            side_effect=lambda proposed, client: proposed,
            autospec=True,
        ),
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
