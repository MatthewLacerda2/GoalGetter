import ast
import io
import os
import sys
import tokenize

# Imported as `backend.tests.backend_linter` by its tests; run as a script
# (`python3 backend/tests/backend_linter.py`) by make and the hooks, where only
# this folder is on the path.
if __package__:
    from backend.tests.hub_rules import hub_violations
else:
    from hub_rules import hub_violations  # type: ignore[import-not-found, no-redef]

# The database layer (#211). Outside repositories/ (and the few files that ARE
# the database's plumbing, see `is_database_layer`) nothing may reach the
# database. The rule looks at what the code does - what a name resolves to,
# what a call is made on - never at how a variable is spelled or how an import
# is aliased, because `import sqlalchemy as sa; sa.select(...)`, `text(...)` and
# `self.session.execute(...)` all went through the name-based version.

# The packages that speak SQL. Outside the database layer only two things of
# theirs may be imported: the session TYPE, which endpoints and services
# annotate and receive through `Depends(get_db)`, and the exceptions, which code
# may catch. Anything else - `select`, `text`, `func`, the whole package under
# any alias - builds or runs a statement.
DATABASE_PACKAGES = {"sqlalchemy", "asyncpg", "psycopg", "psycopg2"}
ALLOWED_DATABASE_IMPORTS = {
    "sqlalchemy.ext.asyncio": {"AsyncSession"},
    "sqlalchemy.exc": None,  # every name: they are exceptions
}

# What only a database session (or a DBAPI cursor) does: a statement. Called on
# anything, these fail - no other object in this codebase has them.
STATEMENT_METHODS = {
    "execute",
    "executemany",
    "add_all",
    "merge",
    "scalar",
    "scalars",
    "get_one",
    "stream_scalars",
    "run_sync",
}
# What a session does that other objects also do - a set's `add`, a
# repository's `delete`, a dict's `get`, a file's `flush`, httpx's `stream`.
# These fail only on a receiver the file got as a session (`session_names`).
# Transaction control (`commit`, `rollback`, `close`, `refresh`) is not here:
# the endpoint owns the transaction, and says when it ends.
SESSION_METHODS = {"add", "delete", "get", "flush", "stream"}
# How a file comes to hold a session: annotated as one, handed one by
# `Depends(get_db)`, or opening one from the factory.
SESSION_TYPES = {"AsyncSession", "Session", "AsyncConnection", "Connection"}
SESSION_SOURCES = {"get_db", "AsyncSessionLocal", "async_sessionmaker", "sessionmaker"}
# The names the codebase gives a session it did not annotate
# (`run_resources_step(session, student_id)`). One signal among the others,
# never the only one: `execute` fails on any receiver whatever its name.
SESSION_CONVENTION = {"db", "session"}

MAX_FILE_LINES = 350

# A file whose bulk is data rather than logic - Gemini prompts, hardcoded
# tables, seed data - opts out of the file-length rule with this marker in its
# header. A 500-line prompt is not a file that needs splitting.
DATA_FILE_MARKER = "# lint: data-file"


def code_line_count(source):
    """Lines that carry code. Comment-only lines and docstrings are free.

    The 350-line rule exists to catch files doing too much, and CLAUDE.md asks
    for documentation aimed at AI agents navigating the code. Counting raw
    lines charges us for writing exactly what we are told to write, so
    explanation is untaxed - blank lines still count, and so does a line of
    code carrying a trailing comment.
    """
    try:
        tokens = list(tokenize.generate_tokens(io.StringIO(source).readline))
    except tokenize.TokenError, IndentationError, SyntaxError:
        # Unparseable: fall back to the raw count rather than silently passing.
        return len(source.splitlines())

    free = set()
    previous = None
    for token in tokens:
        if token.type == tokenize.COMMENT:
            # Only a comment-only line is free; a trailing comment carries code.
            if previous is None or previous.end[0] != token.start[0]:
                free.update(range(token.start[0], token.end[0] + 1))
        elif (
            token.type == tokenize.STRING
            and previous is not None
            and previous.type in (tokenize.INDENT, tokenize.NEWLINE, tokenize.NL, tokenize.DEDENT)
        ):
            # A bare string statement: a docstring.
            free.update(range(token.start[0], token.end[0] + 1))
        if token.type not in (tokenize.NL, tokenize.NEWLINE, tokenize.INDENT, tokenize.DEDENT):
            previous = token
        elif token.type in (tokenize.NEWLINE, tokenize.NL, tokenize.INDENT, tokenize.DEDENT):
            previous = token

    total = len(source.splitlines())
    return total - len(free)


def _terminal_name(node):
    """`x` for `x`, `session` for `self.session`, None for anything else."""
    if isinstance(node, ast.Name):
        return node.id
    if isinstance(node, ast.Attribute):
        return node.attr
    return None


def _is_session_annotation(annotation):
    """`AsyncSession`, `sa.orm.Session`, `AsyncSession | None`, `"AsyncSession"`."""
    if annotation is None:
        return False
    if isinstance(annotation, ast.Constant) and isinstance(annotation.value, str):
        return annotation.value.split(".")[-1].split(" ")[0] in SESSION_TYPES
    if isinstance(annotation, ast.BinOp):
        return _is_session_annotation(annotation.left) or _is_session_annotation(annotation.right)
    if isinstance(annotation, ast.Subscript):
        return _is_session_annotation(annotation.slice)
    return _terminal_name(annotation) in SESSION_TYPES


def _opens_session(value):
    """`AsyncSessionLocal()`, `Depends(get_db)`: an expression whose value is a session."""
    if not isinstance(value, ast.Call):
        return False
    if _terminal_name(value.func) in SESSION_SOURCES:
        return True
    return any(_terminal_name(arg) in SESSION_SOURCES for arg in value.args)


def session_names(tree):
    """Every name (or `self.` attribute) this file holds a session under."""
    names = set(SESSION_CONVENTION)
    for node in ast.walk(tree):
        if isinstance(node, ast.FunctionDef | ast.AsyncFunctionDef | ast.Lambda):
            arguments = node.args
            positional = arguments.posonlyargs + arguments.args
            defaults = [None] * (len(positional) - len(arguments.defaults)) + arguments.defaults
            pairs = list(zip(positional, defaults, strict=True))
            pairs += list(zip(arguments.kwonlyargs, arguments.kw_defaults, strict=True))
            for arg, default in pairs:
                if _is_session_annotation(arg.annotation) or _opens_session(default):
                    names.add(arg.arg)
        elif isinstance(node, ast.withitem) and node.optional_vars is not None:
            if _opens_session(node.context_expr):
                names.add(_terminal_name(node.optional_vars))
        elif isinstance(node, ast.AnnAssign) and _is_session_annotation(node.annotation):
            names.add(_terminal_name(node.target))
    # Assignment is followed to a fixed point, so `self.session = session` and
    # `s = self.session` both carry the session on.
    changed = True
    while changed:
        changed = False
        for node in ast.walk(tree):
            if not isinstance(node, ast.Assign):
                continue
            source = node.value
            if _opens_session(source) or _terminal_name(source) in names:
                for target in node.targets:
                    name = _terminal_name(target)
                    if name is not None and name not in names:
                        names.add(name)
                        changed = True
    names.discard(None)
    return names


def _database_package(module):
    return module is not None and module.split(".")[0] in DATABASE_PACKAGES


def database_access(tree):
    """Where this file reaches the database: [(line, message)]."""
    errors = []
    sessions = session_names(tree)
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for alias in node.names:
                if _database_package(alias.name):
                    errors.append((node.lineno, f"Database import: 'import {alias.name}'"))
        elif isinstance(node, ast.ImportFrom) and node.level == 0:
            if node.module is None or not _database_package(node.module):
                continue
            allowed = ALLOWED_DATABASE_IMPORTS.get(node.module, set())
            for alias in node.names:
                if allowed is not None and alias.name not in allowed:
                    errors.append(
                        (node.lineno, f"Database import: '{alias.name}' from '{node.module}'")
                    )
        elif isinstance(node, ast.Call):
            errors += _database_call(node, sessions)
    return errors


def _database_call(node, sessions):
    func = node.func
    name = _terminal_name(func)
    if name in {"import_module", "__import__"} and node.args:
        first = node.args[0]
        if isinstance(first, ast.Constant) and _database_package(str(first.value)):
            return [(node.lineno, f"Database import: {name}({first.value!r})")]
    if not isinstance(func, ast.Attribute):
        return []
    receiver = func.value
    on_session = _terminal_name(receiver) in sessions or _opens_session(receiver)
    if func.attr in STATEMENT_METHODS or (func.attr in SESSION_METHODS and on_session):
        shown = ast.unparse(func)
        return [(node.lineno, f"Database call outside repositories/: '{shown}()'")]
    return []


def is_database_layer(norm_path):
    """The files that ARE the database: they may speak SQL. Everything else goes
    through repositories/."""
    return (
        "backend/repositories/" in norm_path
        or "backend/models/" in norm_path
        or "backend/alembic/" in norm_path
        or norm_path.endswith("backend/core/database.py")
        # Creates and inspects the throwaway test database itself (#205).
        or norm_path.endswith("backend/tools/disposable_database.py")
    )


def check_source(source, norm_path):
    """Every house-rule violation in `source`, a file at `norm_path` (forward
    slashes, `backend/...`). The unit the linter's own tests exercise."""
    errors = []

    # 1. Enforce general line limits, counting code only (see code_line_count).
    #    Files marked as data (prompts, hardcoded tables) are exempt.
    if DATA_FILE_MARKER not in source:
        line_count = code_line_count(source)
        if line_count > MAX_FILE_LINES:
            errors.append(
                (0, f"File exceeds maximum line limit: {line_count}/{MAX_FILE_LINES} code lines")
            )

    filename = os.path.basename(norm_path)
    is_endpoint = "backend/api/" in norm_path
    is_test = "backend/tests/" in norm_path and filename.startswith("test_")

    # 2. The repository pattern: the database only through repositories/.
    #    Tests and their fixtures may reach it: they set up rows and read them back.
    in_tests = "backend/tests/" in norm_path
    should_check_repo_pattern = not (is_database_layer(norm_path) or in_tests)

    # 3. The hubs (hub_rules.py): each kind of thing is defined in one place.
    should_check_hubs = not in_tests

    if not (should_check_repo_pattern or should_check_hubs or is_endpoint or is_test):
        return errors
    try:
        tree = ast.parse(source, filename=norm_path)
    except SyntaxError as e:
        errors.append((0, f"Failed to parse AST: {e}"))
        return errors

    if should_check_repo_pattern:
        errors += database_access(tree)
    if should_check_hubs:
        errors += hub_violations(tree, norm_path)

    # 4. 50 lines per endpoint and per test function.
    for node in ast.walk(tree):
        if not isinstance(node, ast.FunctionDef | ast.AsyncFunctionDef):
            continue
        if is_endpoint:
            func_type = "Endpoint function"
        elif is_test and node.name.startswith("test_"):
            func_type = "Test function"
        else:
            continue
        start_line = node.decorator_list[0].lineno if node.decorator_list else node.lineno
        func_len = (node.end_lineno or node.lineno) - start_line + 1
        if func_len > 50:
            errors.append(
                (
                    start_line,
                    f"{func_type} '{node.name}' exceeds 50-line limit: {func_len}/50 lines",
                )
            )
    return errors


def check_file(filepath):
    norm_path = filepath.replace("\\", "/")
    # The linter names what it forbids, so it would trip over itself.
    if os.path.basename(norm_path) == "backend_linter.py":
        return []
    try:
        with open(filepath, encoding="utf-8") as f:
            source = f.read()
    except Exception as e:
        return [(0, f"Failed to read file: {e}")]
    return check_source(source, norm_path)


def main():
    # Since this script is now in backend/tests/, its parent dir is the backend root
    backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

    all_errors = {}
    for root, _dirs, files in os.walk(backend_dir):
        if "__pycache__" in root:
            continue

        for file in files:
            if not file.endswith(".py"):
                continue
            filepath = os.path.join(root, file)

            errors = check_file(filepath)
            if errors:
                all_errors[filepath] = errors

    if all_errors:
        print("Linter violations found:")
        for filepath, errors in all_errors.items():
            relpath = os.path.relpath(filepath, backend_dir)
            print(f"\nFile: backend/{relpath}")
            for line, msg in errors:
                print(f"  Line {line}: {msg}")
        sys.exit(1)
    else:
        print("No linter violations found! Codebase conforms to rules.")
        sys.exit(0)


if __name__ == "__main__":
    main()
