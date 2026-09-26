"""The resource search keeps Google's sources and never the model's links (#175).

Built on a real grounded response: its text names eleven URLs, among them a
lichess study and a YouTube ID that no source contains - the invention that left
the first real student with no resources.
"""

import re
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

from backend.core.language import Language
from backend.models.resource import StudyResourceType
from backend.services.gemini.resources.grounding import web_sources
from backend.services.gemini.resources.schema import DescribedSource, DescribedSources
from backend.services.gemini.resources.search_resources import search_resources
from backend.tests.fixtures.captured import grounded_response

MODULE = "backend.services.gemini.resources.search_resources"
GOAL = "00000000-0000-0000-0000-000000000001"
REDIRECT = "https://vertexaisearch.cloud.google.com/grounding-api-redirect/"


def described(*picks, query="xadrez para iniciantes"):
    return DescribedSources(
        resources=[
            DescribedSource(
                source=n, resource_type=kind, name=f"N{n}", description="d", language="PT"
            )
            for n, kind in picks
        ],
        video_query=query,
    )


def run(picks: DescribedSources, language=Language.PORTUGUESE):
    client = MagicMock()
    client.models.generate_content.side_effect = [
        grounded_response(),
        SimpleNamespace(text=picks.model_dump_json()),
    ]
    with patch(MODULE + ".get_client", return_value=client):
        found = search_resources(GOAL, "Xadrez", "Aprender xadrez", "Beginner", [], language)
    return found, client


def test_the_captured_response_offers_its_six_web_sources_and_no_video_page():
    """8 chunks; the two youtube.com ones are the YouTube API's job"""
    sources = web_sources(grounded_response())

    assert len(sources) == 6
    assert "youtube.com" not in {s.site for s in sources}
    assert all(s.uri.startswith(REDIRECT) for s in sources)
    assert "Chess.com" in sources[0].said


def test_every_link_is_a_grounding_source_and_no_link_the_model_wrote_is():
    """The eleven URLs in the text never reach a resource"""
    response = grounded_response()
    written = set(re.findall(r"https?://[^\s)\]]+", response.text)) - {
        c.web.uri for c in response.candidates[0].grounding_metadata.grounding_chunks
    }
    assert "https://lichess.org/study/embed/Xy3x9iuz/1x8vj0h3" in written

    found, _ = run(described(*((n, "webpage") for n in range(3)), (3, "pdf"), (4, "pdf")))

    sources = [s.uri for s in web_sources(response)]
    assert [page.link for page in found.pages] == sources[:5]
    assert not {page.link for page in found.pages} & written


def test_a_number_that_points_nowhere_or_twice_is_dropped():
    found, _ = run(described((9, "webpage"), (-1, "pdf"), (1, "webpage"), (1, "pdf")))

    assert [page.name for page in found.pages] == ["N1"]


def test_three_of_each_type_at_most():
    """Three pages, three PDFs and three videos: the nine a goal is given"""
    found, _ = run(described(*((n, "webpage") for n in range(6))))

    assert [page.name for page in found.pages] == ["N0", "N1", "N2"]
    assert {page.resource_type for page in found.pages} == {StudyResourceType.webpage}


def test_the_rows_carry_the_description_and_the_video_query_and_no_embedding():
    found, client = run(described((2, "pdf")))

    (page,) = found.pages
    assert (page.name, page.description, page.language) == ("N2", "d", "pt")
    assert page.description_embedding is None
    assert found.video_query == "xadrez para iniciantes"
    client.models.embed_content.assert_not_called()


def test_both_prompts_name_the_language_and_the_second_holds_no_link():
    """Prompts are English and name the output language; with no URL in the
    describing prompt there is nothing for the model to copy or alter"""
    _, client = run(described(), language=Language.GERMAN)

    search, describe = (c.kwargs["contents"] for c in client.models.generate_content.call_args_list)
    assert "German" in search and "German" in describe
    assert "http" not in describe
    assert "[5] lichess.org:" in describe
