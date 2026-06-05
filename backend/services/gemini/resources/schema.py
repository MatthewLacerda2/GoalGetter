from pydantic import BaseModel, Field
from backend.models.resource import StudyResourceType

class ResourceRecommendationItem(BaseModel):
    resource_type: StudyResourceType = Field(description="The type of the resource: pdf, webpage, or youtube")
    name: str = Field(description="The name or title of the resource")
    description: str = Field(description="A short, descriptive summary of what this resource teaches (in 20 words or less)")
    language: str = Field(description="The language of the resource")
    link: str = Field(description="The direct, valid URL link to the resource")

class GeminiResourceSearchResults(BaseModel):
    resources: list[ResourceRecommendationItem] = Field(description="List of recommended learning resources")