import uuid
from typing import Any

def convert_uuid_to_str(v: Any) -> str:
    """Utility functions for UUID validation and conversion in Pydantic schemas."""
    if isinstance(v, uuid.UUID):
        return str(v)
    return v
