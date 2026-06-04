import os
import sys
import ast

FORBIDDEN_IMPORTS = {'select', 'insert', 'update', 'delete', 'joinedload', 'selectinload', 'subqueryload'}
FORBIDDEN_METHODS = {'execute', 'add', 'delete'}

def check_file(filepath):
    errors = []
    with open(filepath, 'r', encoding='utf-8') as f:
        try:
            tree = ast.parse(f.read(), filename=filepath)
        except Exception as e:
            return [(0, f"Failed to parse file: {e}")]

    class RepositoryPatternVisitor(ast.NodeVisitor):
        def visit_Import(self, node):
            for alias in node.names:
                name = alias.name.split('.')[-1]
                if name in FORBIDDEN_IMPORTS:
                    errors.append((node.lineno, f"Forbidden import: '{alias.name}'"))
            self.generic_visit(node)

        def visit_ImportFrom(self, node):
            if node.module and ('sqlalchemy' in node.module or 'repositories' in node.module):
                for alias in node.names:
                    if alias.name in FORBIDDEN_IMPORTS:
                        errors.append((node.lineno, f"Forbidden import: '{alias.name}' from '{node.module}'"))
            self.generic_visit(node)

        def visit_Call(self, node):
            # Check for db.execute, db.add, db.delete, session.execute, session.add, session.delete
            if isinstance(node.func, ast.Attribute):
                if isinstance(node.func.value, ast.Name):
                    if node.func.value.id in {'db', 'session'} and node.func.attr in FORBIDDEN_METHODS:
                        errors.append((node.lineno, f"Forbidden direct database session operation: '{node.func.value.id}.{node.func.attr}()'"))
            self.generic_visit(node)

    visitor = RepositoryPatternVisitor()
    visitor.visit(tree)
    return errors

def main():
    backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    exclude_dirs = {
        os.path.join(backend_dir, 'repositories'),
        os.path.join(backend_dir, 'alembic'),
        os.path.join(backend_dir, 'models'),
    }
    exclude_files = {
        os.path.join(backend_dir, 'core', 'database.py'),
        os.path.join(backend_dir, 'main.py'),
    }

    all_errors = {}
    for root, dirs, files in os.walk(backend_dir):
        # Exclude directories
        if any(root.startswith(exclude) for exclude in exclude_dirs):
            continue
        if 'tests' in root or '__pycache__' in root:
            continue

        for file in files:
            if not file.endswith('.py'):
                continue
            filepath = os.path.join(root, file)
            if filepath in exclude_files:
                continue

            errors = check_file(filepath)
            if errors:
                all_errors[filepath] = errors

    if all_errors:
        print("Repository pattern enforcement errors found:")
        for filepath, errors in all_errors.items():
            relpath = os.path.relpath(filepath, backend_dir)
            print(f"\nFile: backend/{relpath}")
            for line, msg in errors:
                print(f"  Line {line}: {msg}")
        sys.exit(1)
    else:
        print("No repository pattern enforcement errors found! Codebase conforms to rules.")
        sys.exit(0)

if __name__ == '__main__':
    main()
