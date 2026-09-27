"""The layer boundaries, checked as import contracts (#211). `make back-lint` runs it.

The contracts and the reason for each live in `backend/pyproject.toml`
(`[tool.importlinter]`), beside ruff's rules. import-linter builds the import
graph of backend/ - every import, including the ones that reach a module only
through another - and exits non-zero when a contract is broken, naming the
chain of imports that broke it.

No cache: import-linter would otherwise write `.import_linter_cache/` into the
mounted worktree, and the graph takes about a second to build anyway.
"""

import sys
from pathlib import Path

from importlinter.cli import lint_imports

CONFIG = Path(__file__).resolve().parents[1] / "pyproject.toml"

if __name__ == "__main__":
    sys.exit(lint_imports(config_filename=str(CONFIG), no_cache=True, no_logo=True))
