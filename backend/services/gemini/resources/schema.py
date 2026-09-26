"""What Gemini returns when it describes the pages Google found (#175).

There is no link field, on purpose: the link is the grounding source the
`source` number points at, never a URL the model types. A model asked for a
link writes one from memory, and those were invented.
"""

from typing import Literal

from pydantic import BaseModel, Field


class DescribedSource(BaseModel):
    source: int = Field(description="The number of the source this describes")
    resource_type: Literal["webpage", "pdf"]
    name: str = Field(description="The page's name, a few words")
    description: str = Field(description="What it teaches this student, 20 words at most")
    language: str = Field(description="Two-letter ISO 639-1 code of the page's language")


class DescribedSources(BaseModel):
    resources: list[DescribedSource]
    video_query: str = Field(description="One YouTube search query for videos for this student")
