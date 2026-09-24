"""Tutor-chat fixtures, registered in the root conftest's `pytest_plugins`.

They used to be imported by each tutor test module instead, to keep sibling
branches off one shared conftest line. That cost every consumer a
`# noqa: F811` on the fixture parameter, so they are registered here like the
other six fixture modules."""

from datetime import UTC, datetime, timedelta

import pytest

from backend.models.chat_message import ChatMessage

T0 = datetime(2026, 6, 6, 9, 0, tzinfo=UTC)


@pytest.fixture
def exchange_factory(test_db):
    """Create exchanges for a goal, one minute apart from T0 (i=0 is the oldest)."""

    async def _create(goal, count=1, **kwargs):
        rows = [
            ChatMessage(
                student_id=goal.student_id,
                goal_id=goal.id,
                prompt=f"q{i}",
                tutor_responses=[f"a{i}", f"b{i}"],
                created_at=T0 + timedelta(minutes=i),
                **kwargs,
            )
            for i in range(count)
        ]
        test_db.add_all(rows)
        await test_db.flush()
        return rows

    return _create
