from pydantic import BaseModel
from typing import List, Optional

class GeminiResourceSearchResultItem(BaseModel):
    model_config = {"frozen": True}
    
    name: str
    description: str
    language: str
    link: str

class GeminiResourceSearchResults(BaseModel):
    resources: List[GeminiResourceSearchResultItem]

class ResourceSearchResultItem(BaseModel):
    language: str
    name: str
    description: str
    link: str
    image_url: Optional[str] = None

class ResourceSearchResults(BaseModel):
    resources: List[ResourceSearchResultItem]