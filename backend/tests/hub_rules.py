"""The hubs (#231): each kind of thing has one home, and nothing defines it anywhere else.

Nothing that is used more than once is written where it is used: a Pydantic
model is a schema, a route is an endpoint, a table is a model, and each of them
lives in the folder CLAUDE.md's hub map names, so a reader finds it without
searching and a gate can say that nothing sits anywhere else. The repository
rule (`backend_linter.py`, "database access only through repositories/") is the
first of them; these are the rest.

Each rule reads what a file *does* - what a class inherits from, what a call
resolves to, what a name was imported as - never what something is called.
#212 rejected name checks: `class FooSchema` in services/ passed a rule that
looked for the word "schema", and so would `class Foo(pydantic.BaseModel)`.
Names are resolved through the file's own imports, so an alias
(`import pydantic as pd; class X(pd.BaseModel)`) is the same finding.

Tests are exempt: a test builds whatever fake it needs, and nothing imports it.
"""

import ast
import re
from collections.abc import Callable
from dataclasses import dataclass

# A check reads one parsed file and its import table and answers the lines
# where it defines or uses the hub's kind.
Finder = Callable[[ast.Module, dict[str, str]], list[int]]


def import_table(tree: ast.Module) -> dict[str, str]:
    """What each name bound by an import stands for: `{"pd": "pydantic",
    "Model": "pydantic.BaseModel"}`. Relative imports are left out: the codebase
    writes `backend.`-absolute ones (ruff's `TID252`)."""
    table: dict[str, str] = {}
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for alias in node.names:
                if alias.asname:
                    table[alias.asname] = alias.name
                else:
                    top = alias.name.split(".")[0]
                    table[top] = top
        elif isinstance(node, ast.ImportFrom) and node.level == 0 and node.module:
            for alias in node.names:
                table[alias.asname or alias.name] = f"{node.module}.{alias.name}"
    return table


def qualified(node: ast.expr, table: dict[str, str]) -> str | None:
    """`pd.BaseModel` -> `pydantic.BaseModel`, through the file's imports. None
    for a name no import bound, or for anything that is not a dotted name."""
    if isinstance(node, ast.Name):
        return table.get(node.id)
    if isinstance(node, ast.Attribute):
        owner = qualified(node.value, table)
        return None if owner is None else f"{owner}.{node.attr}"
    return None


def references(tree: ast.Module, table: dict[str, str], targets: set[str]) -> list[int]:
    """Lines that name any of `targets` (fully qualified), however imported."""
    return sorted(
        {
            node.lineno
            for node in ast.walk(tree)
            if isinstance(node, ast.Name | ast.Attribute) and qualified(node, table) in targets
        }
    )


def _classes_derived_from(
    tree: ast.Module, table: dict[str, str], is_root: Callable[[str], bool]
) -> list[ast.ClassDef]:
    """Every class in the file that inherits, directly or through another class
    of the same file, from an imported class `is_root` accepts."""
    classes = [node for node in ast.walk(tree) if isinstance(node, ast.ClassDef)]
    derived: dict[str, ast.ClassDef] = {}
    changed = True
    while changed:
        changed = False
        for cls in classes:
            if cls.name in derived:
                continue
            for base in cls.bases:
                name = qualified(base, table)
                local = isinstance(base, ast.Name) and base.id in derived
                if local or (name is not None and is_root(name)):
                    derived[cls.name] = cls
                    changed = True
                    break
    return list(derived.values())


# --- Pydantic models ------------------------------------------------------

PYDANTIC_ROOTS = {
    "pydantic.BaseModel",
    "pydantic.main.BaseModel",
    "pydantic.RootModel",
    "pydantic.root_model.RootModel",
    "pydantic_settings.BaseSettings",
}
# Subclassing a class imported from a schema hub is defining a model too.
SCHEMA_MODULES = re.compile(r"^backend\.(schemas|services\.gemini\.[^.]+\.schema)\.")


def _is_pydantic_root(name: str) -> bool:
    return name in PYDANTIC_ROOTS or bool(SCHEMA_MODULES.match(name))


def pydantic_models(tree: ast.Module, table: dict[str, str]) -> list[int]:
    lines = [cls.lineno for cls in _classes_derived_from(tree, table, _is_pydantic_root)]
    # A model built at runtime, or a Pydantic dataclass, is a model all the same.
    for node in ast.walk(tree):
        if isinstance(node, ast.Call) and qualified(node.func, table) == "pydantic.create_model":
            lines.append(node.lineno)
        elif isinstance(node, ast.Name | ast.Attribute):
            name = qualified(node, table) or ""
            if name.startswith("pydantic.dataclasses"):
                lines.append(node.lineno)
    return sorted(set(lines))


# --- Routes ---------------------------------------------------------------

ROUTERS = {"fastapi.APIRouter", "fastapi.routing.APIRouter"}
APPS = {"fastapi.FastAPI", "fastapi.applications.FastAPI"}
# What declares a route on a router or on the app: the decorators and the
# methods that add one without a decorator.
ROUTE_METHODS = {
    "get",
    "post",
    "put",
    "patch",
    "delete",
    "head",
    "options",
    "trace",
    "api_route",
    "route",
    "websocket",
    "websocket_route",
    "add_api_route",
    "add_route",
    "add_api_websocket_route",
    "add_websocket_route",
}


def routes(tree: ast.Module, table: dict[str, str]) -> list[int]:
    """A router made, or a route declared on a router or on the app."""
    lines: list[int] = []
    owners: set[str] = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.Call):
            made = qualified(node.func, table)
            if made in ROUTERS:
                lines.append(node.lineno)
        if isinstance(node, ast.Assign | ast.AnnAssign) and isinstance(node.value, ast.Call):
            if qualified(node.value.func, table) in ROUTERS | APPS:
                targets = node.targets if isinstance(node, ast.Assign) else [node.target]
                owners.update(t.id for t in targets if isinstance(t, ast.Name))
    for node in ast.walk(tree):
        if not (isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute)):
            continue
        receiver = node.func.value
        if node.func.attr in ROUTE_METHODS and isinstance(receiver, ast.Name):
            if receiver.id in owners:
                lines.append(node.lineno)
    return sorted(set(lines))


# --- ORM tables -----------------------------------------------------------

ORM_ROOTS = {"sqlalchemy.orm.DeclarativeBase", "sqlalchemy.orm.DeclarativeBaseNoMeta"}


def _is_orm_root(name: str) -> bool:
    return name in ORM_ROOTS or name.startswith("backend.models.")


def orm_tables(tree: ast.Module, table: dict[str, str]) -> list[int]:
    """A mapped class: one that names its table, or inherits from the
    declarative base (or from a model)."""
    lines = [cls.lineno for cls in _classes_derived_from(tree, table, _is_orm_root)]
    for cls in (node for node in ast.walk(tree) if isinstance(node, ast.ClassDef)):
        for statement in cls.body:
            targets = []
            if isinstance(statement, ast.Assign):
                targets = statement.targets
            elif isinstance(statement, ast.AnnAssign):
                targets = [statement.target]
            if any(
                isinstance(t, ast.Name) and t.id in {"__tablename__", "__table__"} for t in targets
            ):
                lines.append(cls.lineno)
    return sorted(set(lines))


# --- The rest: one reference is the finding -------------------------------

# The HTTP error types. Everything else raises `ApiError(ErrorCode.X)`, whose
# code and status are declared once in core/errors/codes.py (#214).
HTTP_ERRORS = {
    f"{module}.{name}"
    for module in ("fastapi", "fastapi.exceptions", "starlette.exceptions")
    for name in ("HTTPException", "WebSocketException")
}
# The process environment. core/config.py reads it once, into `settings`.
ENVIRONMENT = {"os.environ", "os.environb", "os.getenv", "os.getenvb", "os.putenv", "os.unsetenv"}
ENVIRONMENT |= {"dotenv.load_dotenv", "dotenv.dotenv_values", "dotenv.find_dotenv"}
# The wall clock. core/clock.py answers "now" in UTC, and a test freezes it
# there; a call anywhere else is a moment no test can move.
CLOCK = {
    "datetime.datetime.now",
    "datetime.datetime.utcnow",
    "datetime.datetime.today",
    "datetime.date.today",
    "time.time",
    "time.time_ns",
}


@dataclass(frozen=True)
class Hub:
    kind: str
    # Where the kind may be defined: regexes on the file's path from `backend/`.
    homes: tuple[str, ...]
    find: Finder
    help: str


HUBS = (
    Hub(
        "Pydantic model",
        (
            r"backend/schemas/",
            r"backend/services/gemini/[^/]+/schema\.py$",
            r"backend/core/config\.py$",
            r"backend/core/errors/",
        ),
        pydantic_models,
        "an API body is in schemas/, a shape Gemini returns in its use case's "
        "schema.py, the settings in core/config.py",
    ),
    Hub(
        "Route",
        (r"backend/api/",),
        routes,
        "every route is declared under api/, on a router main.py includes",
    ),
    Hub(
        "ORM table",
        (r"backend/models/",),
        orm_tables,
        "a table is a class in models/",
    ),
    Hub(
        "HTTP error",
        (r"backend/core/errors/",),
        lambda tree, table: references(tree, table, HTTP_ERRORS),
        "raise ApiError(ErrorCode.X) from core/errors/; a new error is a new ErrorCode",
    ),
    Hub(
        "Environment read",
        (r"backend/core/config\.py$", r"backend/tools/"),
        lambda tree, table: references(tree, table, ENVIRONMENT),
        "read `settings` from core/config.py; a new variable is a new field there",
    ),
    Hub(
        "Wall clock",
        (r"backend/core/clock\.py$",),
        lambda tree, table: references(tree, table, CLOCK),
        "use core/clock.py: now() for the moment, today() for the app's date",
    ),
)


def _is_home(norm_path: str, hub: Hub) -> bool:
    return any(re.search(rf"(^|/){home}", norm_path) for home in hub.homes)


def hub_violations(tree: ast.Module, norm_path: str) -> list[tuple[int, str]]:
    """Every kind this file defines outside its hub: [(line, message)]."""
    if re.search(r"(^|/)backend/tests/", norm_path):
        return []
    table = import_table(tree)
    errors: list[tuple[int, str]] = []
    for hub in HUBS:
        if _is_home(norm_path, hub):
            continue
        for line in hub.find(tree, table):
            errors.append((line, f"{hub.kind} outside its hub: {hub.help} (CLAUDE.md, hub map)"))
    return errors
