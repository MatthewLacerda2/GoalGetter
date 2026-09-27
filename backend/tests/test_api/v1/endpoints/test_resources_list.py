import uuid
from datetime import timedelta

from backend.models.resource import Resource, StudyResourceType
from backend.tests.fixtures.lessons import T0

ENDPOINT = "/api/v1/resources"


async def add_resource(db, goal, kind, name, image_url=None, **fields):
    db.add(
        Resource(
            **fields,
            goal_id=goal.id,
            resource_type=kind,
            name=name,
            description=f"About {name}",
            language="en",
            link=f"https://example.com/{name}",
            image_url=image_url,
        )
    )
    await db.flush()


async def test_resources_are_grouped_by_kind(auth_client, test_db, test_user, goal_factory):
    goal = await goal_factory(test_user, active=True)
    await add_resource(test_db, goal, StudyResourceType.youtube, "video", "https://img/v.jpg")
    await add_resource(test_db, goal, StudyResourceType.pdf, "book")
    await add_resource(test_db, goal, StudyResourceType.webpage, "site")

    response = await auth_client.get(ENDPOINT)

    assert response.status_code == 200
    assert response.json() == {
        "youtube": [
            {
                "name": "video",
                "description": "About video",
                "url": "https://example.com/video",
                "image_url": "https://img/v.jpg",
            }
        ],
        "books": [
            {
                "name": "book",
                "description": "About book",
                "url": "https://example.com/book",
                "image_url": None,
            }
        ],
        "websites": [
            {
                "name": "site",
                "description": "About site",
                "url": "https://example.com/site",
                "image_url": None,
            }
        ],
    }


async def test_resources_only_of_the_active_goal(
    auth_client, test_db, test_user, student_factory, goal_factory
):
    active = await goal_factory(test_user, active=True)
    inactive = await goal_factory(test_user, name="Guitar")
    other = await student_factory(email="o@example.com", google_id="other")
    theirs = await goal_factory(other, active=True)
    await add_resource(test_db, active, StudyResourceType.webpage, "mine")
    await add_resource(test_db, inactive, StudyResourceType.webpage, "inactive")
    await add_resource(test_db, theirs, StudyResourceType.webpage, "theirs")

    body = (await auth_client.get(ENDPOINT)).json()

    assert [r["name"] for r in body["websites"]] == ["mine"]


async def test_resources_come_in_the_order_they_were_found(
    auth_client, test_db, test_user, goal_factory
):
    """Oldest first, the id breaking a tie (#207). Written here in neither
    order, so a query with no ORDER BY - which answers in the order the rows
    were written - fails this."""
    goal = await goal_factory(test_user, active=True)
    for name, minute, key in (
        ("third", 2, 3),
        ("tie-high", 0, 9),
        ("second", 1, 2),
        ("tie-low", 0, 8),
    ):
        await add_resource(
            test_db,
            goal,
            StudyResourceType.webpage,
            name,
            created_at=T0 + timedelta(minutes=minute),
            id=uuid.UUID(int=key),
        )

    body = (await auth_client.get(ENDPOINT)).json()

    assert [r["name"] for r in body["websites"]] == ["tie-low", "tie-high", "second", "third"]


async def test_resources_still_being_found_are_empty_lists(auth_client, test_user, goal_factory):
    await goal_factory(test_user, active=True)
    response = await auth_client.get(ENDPOINT)
    assert response.status_code == 200
    assert response.json() == {"youtube": [], "books": [], "websites": []}


async def test_resources_without_active_goal_is_404(auth_client, test_user, goal_factory):
    await goal_factory(test_user)
    response = await auth_client.get(ENDPOINT)
    assert response.status_code == 404
    assert response.json()["code"] == "no_active_goal"
