"""The nightly chain writes to the student in his language (#173): it has no
message of his to read one from, so it is `students.language`, else the
language his goals are written in."""

import pytest

from backend.core.language import Language
from backend.models.student_context import StudentContext
from backend.services.jobs.student_chain import run_student_chain
from backend.tests.fixtures.jobs import chain_gemini


@pytest.mark.asyncio
async def test_every_step_is_given_his_chosen_language(test_db, test_user, goal_factory):
    await goal_factory(test_user)
    test_user.language = "de"
    await test_db.commit()

    calls = []
    with chain_gemini(test_db, calls):
        await run_student_chain(str(test_user.id))

    assert {name: args[-1] for name, args in calls} == {
        "context": Language.GERMAN,
        "questions": Language.GERMAN,
        "resources": Language.GERMAN,
    }


@pytest.mark.asyncio
async def test_without_a_choice_the_language_of_his_goals(test_db, test_user, goal_factory):
    await goal_factory(test_user, name="Xadrez", description="Eu quero aprender as aberturas")
    test_db.add(StudentContext(student_id=test_user.id, state="s", metacognition="m"))
    await test_db.commit()

    calls = []
    with chain_gemini(test_db, calls):
        await run_student_chain(str(test_user.id))

    assert {args[-1] for _, args in calls} == {Language.PORTUGUESE}
