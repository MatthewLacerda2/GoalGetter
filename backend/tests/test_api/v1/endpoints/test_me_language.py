"""students.language (#172): the app sends X-Student-Language on every
request, the backend mirrors it, GET /me reads it back."""

import pytest

from backend.models.student import Student

ENDPOINT = "/api/v1/me"
HEADER = "X-Student-Language"


@pytest.mark.asyncio
async def test_a_student_the_app_never_told_has_no_language(auth_client):
    response = await auth_client.get(ENDPOINT)

    assert response.json()["language"] is None


@pytest.mark.asyncio
async def test_the_header_is_stored_and_read_back(auth_client, test_db, test_user):
    response = await auth_client.get(ENDPOINT, headers={HEADER: "pt"})

    assert response.json()["language"] == "pt"
    assert (await test_db.get(Student, test_user.id)).language == "pt"


@pytest.mark.asyncio
async def test_changing_it_in_the_app_changes_it_here(auth_client):
    await auth_client.get(ENDPOINT, headers={HEADER: "pt"})

    response = await auth_client.get(ENDPOINT, headers={HEADER: "de"})

    assert response.json()["language"] == "de"


@pytest.mark.asyncio
@pytest.mark.parametrize("sent", [None, "xx", "pt-BR"])
async def test_no_usable_header_leaves_the_stored_language_alone(auth_client, sent):
    await auth_client.get(ENDPOINT, headers={HEADER: "fr"})

    headers = {HEADER: sent} if sent else {}
    response = await auth_client.get(ENDPOINT, headers=headers)

    assert response.status_code == 200
    assert response.json()["language"] == "fr"


@pytest.mark.asyncio
async def test_a_new_student_signs_up_with_the_language_he_chose(
    client, mock_google_verify, test_db
):
    mock_google_verify.side_effect = lambda t, r, c: {
        "email": "nova@example.com",
        "sub": "google_nova",
        "name": "Nova",
        "aud": c,
    }

    response = await client.post(
        "/api/v1/auth/signup", headers={"Authorization": "Bearer google", HEADER: "es"}
    )

    student = await test_db.get(Student, response.json()["student"]["id"])
    assert student.language == "es"
