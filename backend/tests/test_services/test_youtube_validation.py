import pytest

from backend.models.resource import StudyResourceType
from backend.services.resources.link_validation import validate_resources
from backend.tests.test_services.test_link_validation import FakeClient, FakeResponse, make

MODULE = "backend.services.resources.link_validation"

CHANNEL_URL = "https://www.youtube.com/@italianteacher"
AVATAR = "https://yt3.ggpht.com/avatar.jpg"


def youtube_payload(thumbnails=None, privacy=None):
    snippet = {"thumbnails": thumbnails} if thumbnails is not None else {}
    item = {"snippet": snippet}
    if privacy:
        item["status"] = {"privacyStatus": privacy}
    return {"items": [item]}


@pytest.mark.asyncio
async def test_real_channel_is_kept_and_its_picture_stored(monkeypatch):
    """A channel the Data API knows survives, and its avatar lands on the resource"""
    monkeypatch.setattr(MODULE + ".YOUTUBE_API_KEY", "test-key")
    resource = make(StudyResourceType.youtube, CHANNEL_URL)
    client = FakeClient({
        "youtube/v3/channels": FakeResponse(
            200, payload=youtube_payload({"high": {"url": AVATAR}})
        )
    })

    kept = await validate_resources([resource], client=client)

    assert kept == [resource]
    assert resource.image_url == AVATAR


@pytest.mark.asyncio
async def test_channel_without_a_picture_is_dropped(monkeypatch):
    """The profile-picture rule: no avatar means we do not keep it"""
    monkeypatch.setattr(MODULE + ".YOUTUBE_API_KEY", "test-key")
    resource = make(StudyResourceType.youtube, CHANNEL_URL)
    client = FakeClient({
        "youtube/v3/channels": FakeResponse(200, payload=youtube_payload({}))
    })

    assert await validate_resources([resource], client=client) == []


@pytest.mark.asyncio
async def test_unknown_video_is_dropped(monkeypatch):
    """Gemini invented a video id: the API returns no items, so it goes"""
    monkeypatch.setattr(MODULE + ".YOUTUBE_API_KEY", "test-key")
    resource = make(StudyResourceType.youtube, "https://youtu.be/abcdefghijk")
    client = FakeClient({"youtube/v3/videos": FakeResponse(200, payload={"items": []})})

    assert await validate_resources([resource], client=client) == []


@pytest.mark.asyncio
async def test_private_video_is_dropped(monkeypatch):
    """A video that exists but is not public is useless to a student"""
    monkeypatch.setattr(MODULE + ".YOUTUBE_API_KEY", "test-key")
    resource = make(StudyResourceType.youtube, "https://youtu.be/abcdefghijk")
    client = FakeClient({
        "youtube/v3/videos": FakeResponse(
            200, payload=youtube_payload({"high": {"url": AVATAR}}, privacy="private")
        )
    })

    assert await validate_resources([resource], client=client) == []


@pytest.mark.asyncio
async def test_non_youtube_link_typed_as_youtube_is_dropped(monkeypatch):
    """A link that is not recognisably YouTube never reaches the API"""
    monkeypatch.setattr(MODULE + ".YOUTUBE_API_KEY", "test-key")
    resource = make(StudyResourceType.youtube, "https://vimeo.com/12345")
    client = FakeClient({})

    assert await validate_resources([resource], client=client) == []
    assert client.calls == []
