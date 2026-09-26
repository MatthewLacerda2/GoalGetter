import pytest

from backend.models.resource import Resource, StudyResourceType

ENDPOINT = "/api/v1/resources"


async def add_resource(db, goal, kind, name, image_url=None):
    db.add(
        Resource(
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


@pytest.mark.asyncio
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


@pytest.mark.asyncio
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


@pytest.mark.asyncio
async def test_resources_still_being_found_are_empty_lists(auth_client, test_user, goal_factory):
    await goal_factory(test_user, active=True)
    response = await auth_client.get(ENDPOINT)
    assert response.status_code == 200
    assert response.json() == {"youtube": [], "books": [], "websites": []}


@pytest.mark.asyncio
async def test_resources_without_active_goal_is_404(auth_client, test_user, goal_factory):
    await goal_factory(test_user)
    response = await auth_client.get(ENDPOINT)
    assert response.status_code == 404
    assert response.json()["detail"] == "No active goal"


@pytest.mark.asyncio
async def test_resources_requires_auth(client):
    assert (await client.get(ENDPOINT)).status_code == 401
