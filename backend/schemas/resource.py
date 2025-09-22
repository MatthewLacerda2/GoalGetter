from pydantic import BaseModel, ConfigDict
from typing import List, Optional
from backend.models.resource import StudyResourceType

class ResourceItem(BaseModel):
    id: str
    resource_type: StudyResourceType
    name: str
    description: str
    link: str
    image_url: Optional[str] = None
    
    model_config = ConfigDict(from_attributes=True, arbitrary_types_allowed=True)

class ResourceResponse(BaseModel):
    resources: List[ResourceItem]
    
    model_config = ConfigDict(from_attributes=True, arbitrary_types_allowed=True)
    
    