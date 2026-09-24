"""Who a fictitious student is. Shared by POST /auth/dev-login and the
`make claude` seeder, so both land on the same row.

The name prefix is the only marker that a student is fictitious (decided in
#51, no database flag).
"""

import re
from dataclasses import dataclass

FICTITIOUS_PREFIX = "Fictitious "


@dataclass(frozen=True)
class FictitiousIdentity:
    name: str
    google_id: str
    email: str


def fictitious_identity(name: str) -> FictitiousIdentity:
    """`Claude` -> `Fictitious Claude`, google_id `fictitious-claude`, and an
    email on the reserved `.invalid` TLD, which can never be delivered."""
    name = name.strip()
    if not name.startswith(FICTITIOUS_PREFIX):
        name = FICTITIOUS_PREFIX + name
    slug = re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")
    return FictitiousIdentity(name=name, google_id=slug, email=f"{slug}@fictitious.invalid")
