from pydantic import BaseModel, Field


class ResourceItem(BaseModel):
    """One curated resource, as the resources screen shows it."""
    name: str
    description: str
    url: str = Field(..., description="The stored, validated link")
    image_url: str | None = Field(None, description="Only YouTube resources carry a picture")


class ResourcesResponse(BaseModel):
    """GET /resources: the active goal's resources, grouped by kind. A goal whose
    background search has not finished yet returns three empty lists."""
    youtube: list[ResourceItem]
    books: list[ResourceItem] = Field(..., description="Resources of type pdf")
    websites: list[ResourceItem] = Field(..., description="Resources of type webpage")
