"""The backend's own modules, for tests that read the code rather than run it.

Found by file, not by `pkgutil`: several folders here have no `__init__.py`
(`services/`, `services/gemini/`, `services/gemini/chat/`), and `pkgutil`
walks past a namespace package without a word - which is how a check that
means "every module" quietly becomes "most of them".
"""

import importlib
from pathlib import Path
from types import ModuleType

BACKEND = Path(__file__).resolve().parents[2]


def modules_under(relative: str) -> list[ModuleType]:
    """Every module under `backend/<relative>`, imported, `__init__` included."""
    root = BACKEND / relative
    modules = []
    for path in sorted(root.rglob("*.py")):
        parts = path.relative_to(BACKEND.parent).with_suffix("").parts
        if parts[-1] == "__init__":
            parts = parts[:-1]
        modules.append(importlib.import_module(".".join(parts)))
    return modules
