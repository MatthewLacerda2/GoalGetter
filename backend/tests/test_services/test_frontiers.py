"""Moving the target, and refusing to (#133).

The frontier is reconsidered inside the context review, so these exercise the
context step - with Gemini mocked, as everywhere. What is under test is what
the step does with the answer: an append, or nothing at all.

The last test is the one the issue asks for by name, and it is the only one
here that lets the real prompt be built: the question generator is called for
real with its *client* replaced, so the assertion is on the text Gemini would
have received.
"""

from contextlib import contextmanager
from types import SimpleNamespace
from unittest.mock import patch

import pytest

from backend.models.frontier import Frontier
from backend.models.student_context import StudentContext
from backend.repositories.frontier_repository import FrontierRepository
from backend.repositories.student_context_repository import StudentContextRepository
from backend.services.gemini.lesson.schema import GeminiLessonQuestionsResponse
from backend.services.jobs.steps.context import run_context_step
from backend.services.jobs.steps.questions import run_questions_step
from backend.tests.fixtures.jobs import ELSEWHERE, SUBJECT, chain_gemini, review
from backend.tests.fixtures.lessons import at

LESSON = "backend.services.gemini.lesson.lesson_generation"
CIRCUITS = "Understand circuits."


async def studied(test_db, test_user, goal_factory, question_factory, answer_factory, **kwargs):
    """A student with a goal, one answer behind him and one standing reading -
    everything the review path needs to be the one that runs."""
    goal = await goal_factory(test_user, name="Circuits", description=CIRCUITS, **kwargs)
    question = await question_factory(goal, text="What is a resistor?")
    await answer_factory(question, correct=False, answered_at=at(10))
    await StudentContextRepository(test_db).create(
        StudentContext(student_id=test_user.id, state="Beginner", metacognition="Curious")
    )
    await test_db.commit()
    return goal


async def history(test_db, goal) -> list[str]:
    return [row.definition for row in await FrontierRepository(test_db).list_by_goal(goal.id)]


@pytest.mark.asyncio
async def test_a_night_that_moves_nothing_writes_no_row(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """The normal night: he is still working at the frontier he is on"""
    goal = await studied(test_db, test_user, goal_factory, question_factory, answer_factory)

    calls = []
    with chain_gemini(test_db, calls):
        assert await run_context_step(test_db, str(test_user.id)) is False

    assert await history(test_db, goal) == [CIRCUITS]
    assert [name for name, _ in calls] == ["review"]


@pytest.mark.asyncio
async def test_a_move_appends_a_row_and_leaves_the_one_before_it(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """He has learned what circuits are, so he is taken on to robotics"""
    goal = await studied(test_db, test_user, goal_factory, question_factory, answer_factory)

    calls = []
    with chain_gemini(test_db, calls, reviewed=review(moved=[(0, "Robotics.")])):
        assert await run_context_step(test_db, str(test_user.id)) is True

    assert await history(test_db, goal) == [CIRCUITS, "Robotics."]
    assert (await FrontierRepository(test_db).current(goal.id)).definition == "Robotics."


@pytest.mark.asyncio
async def test_a_frontier_on_a_different_subject_is_refused(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """The app wandering off: the proposal sits nowhere near the goal itself"""
    goal = await studied(
        test_db,
        test_user,
        goal_factory,
        question_factory,
        answer_factory,
        description_embedding=SUBJECT,
    )

    calls = []
    with chain_gemini(
        test_db, calls, reviewed=review(moved=[(0, "Baroque opera.")]), embedding=ELSEWHERE
    ):
        assert await run_context_step(test_db, str(test_user.id)) is False

    assert await history(test_db, goal) == [CIRCUITS]


@pytest.mark.asyncio
async def test_a_move_is_written_when_there_is_nothing_to_check_it_against(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """The goal is not embedded yet: nothing here is ever blocked by that"""
    goal = await studied(test_db, test_user, goal_factory, question_factory, answer_factory)

    calls = []
    with chain_gemini(test_db, calls, reviewed=review(moved=[(0, "Robotics.")])):
        await run_context_step(test_db, str(test_user.id))

    assert await history(test_db, goal) == [CIRCUITS, "Robotics."]


@pytest.mark.asyncio
async def test_the_embedding_the_check_paid_for_is_kept_on_the_row(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """One billed vector, stored: the midnight backfill's queue is the null"""
    goal = await studied(
        test_db,
        test_user,
        goal_factory,
        question_factory,
        answer_factory,
        description_embedding=SUBJECT,
    )

    calls = []
    with chain_gemini(test_db, calls, reviewed=review(moved=[(0, "Robotics.")])):
        await run_context_step(test_db, str(test_user.id))

    rows = await FrontierRepository(test_db).list_by_goal(goal.id)
    assert rows[-1].definition_embedding is not None
    assert [name for name, _ in calls] == ["review", "embedding"]


@pytest.mark.asyncio
async def test_a_definition_that_repeats_the_current_frontier_is_not_a_move(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """Append-only means an append must say something; this one does not"""
    goal = await studied(test_db, test_user, goal_factory, question_factory, answer_factory)

    calls = []
    with chain_gemini(test_db, calls, reviewed=review(moved=[(0, CIRCUITS)])):
        assert await run_context_step(test_db, str(test_user.id)) is False

    assert await history(test_db, goal) == [CIRCUITS]


@pytest.mark.asyncio
async def test_an_index_the_model_invented_or_repeated_moves_nothing_twice(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """One goal was shown: index 7 does not exist, and 0 twice moves once"""
    goal = await studied(test_db, test_user, goal_factory, question_factory, answer_factory)

    calls = []
    moves = [(7, "Nowhere."), (0, "Robotics."), (0, "Robotics again.")]
    with chain_gemini(test_db, calls, reviewed=review(moved=moves)):
        assert await run_context_step(test_db, str(test_user.id)) is True

    assert await history(test_db, goal) == [CIRCUITS, "Robotics."]


@pytest.mark.asyncio
async def test_the_review_prompt_sees_the_frontier_beside_what_he_asked_for(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """Both, because the day-one goal is what says a move is a move"""
    goal = await studied(test_db, test_user, goal_factory, question_factory, answer_factory)
    await FrontierRepository(test_db).create(Frontier(goal_id=goal.id, definition="Robotics."))
    await test_db.commit()

    calls = []
    with chain_gemini(test_db, calls):
        await run_context_step(test_db, str(test_user.id))

    [seen] = dict(calls)["review"][0]
    assert (seen.description, seen.frontier) == (CIRCUITS, "Robotics.")


@contextmanager
def a_recording_client(prompts: list[str]):
    """The question generator run for real, with only its client replaced: what
    the prompt says is the thing under test, and no call leaves the machine."""

    def generate_content(model, contents, config):
        prompts.append(contents)
        return SimpleNamespace(text=GeminiLessonQuestionsResponse(questions=[]).model_dump_json())

    client = SimpleNamespace(models=SimpleNamespace(generate_content=generate_content))
    with patch(LESSON + ".get_client", lambda: client):
        yield


@pytest.mark.asyncio
async def test_moving_the_frontier_changes_what_the_prompt_asks_for(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """The claim the issue is for: generation aims at the frontier, not the goal"""
    goal = await studied(test_db, test_user, goal_factory, question_factory, answer_factory)
    # Three he can answer beside the one he missed: a generation is only bought
    # for a student the bank has become too easy for (#135).
    for i in range(3):
        held = await question_factory(goal, text=f"What is Ohm's law? ({i})")
        await answer_factory(held, correct=True, answered_at=at(11 + i))
    await test_db.commit()

    prompts: list[str] = []
    with a_recording_client(prompts):
        await run_questions_step(test_db, str(test_user.id))

        await FrontierRepository(test_db).create(Frontier(goal_id=goal.id, definition="Robotics."))
        await test_db.commit()
        await run_questions_step(test_db, str(test_user.id))

    before, after = (f'current frontier: "{text}"' for text in (CIRCUITS, "Robotics."))
    assert before in prompts[0] and after not in prompts[0]
    assert after in prompts[1] and CIRCUITS in prompts[1]
