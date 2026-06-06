import os
import sys
import ast

FORBIDDEN_IMPORTS = {'select', 'insert', 'update', 'delete', 'joinedload', 'selectinload', 'subqueryload'}
FORBIDDEN_METHODS = {'execute', 'add', 'delete'}

def check_file(filepath):
    errors = []
    
    # Exclude the linter itself from all checks
    norm_path = filepath.replace("\\", "/")
    if "backend_linter.py" in norm_path:
        return []

    # Read the file lines to perform line count checks
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception as e:
        return [(0, f"Failed to read file: {e}")]
        
    line_count = len(lines)
    
    # 1. Enforce general line limits (max 350 lines)
    if line_count > 350:
        errors.append((0, f"File exceeds maximum line limit: {line_count}/350 lines"))
        
    # Check path characteristics
    filename = os.path.basename(norm_path)
    is_endpoint = "backend/api/" in norm_path
    is_test = "backend/tests/" in norm_path and filename.startswith("test_")
    is_repo = "backend/repositories/" in norm_path
    is_model = "backend/models/" in norm_path
    is_alembic = "backend/alembic/" in norm_path
    is_db_config = "backend/core/database.py" in norm_path
    is_main = "backend/main.py" in norm_path
    
    # 2. Enforce Repository Pattern rules (skip for repositories, models, alembic, db configs, main, and tests)
    should_check_repo_pattern = not (is_repo or is_model or is_alembic or is_db_config or is_main or is_test)
    
    should_ast_parse = should_check_repo_pattern or is_endpoint or is_test
    
    if should_ast_parse:
        try:
            tree = ast.parse("".join(lines), filename=filepath)
        except Exception as e:
            errors.append((0, f"Failed to parse AST: {e}"))
            return errors
            
        class LinterVisitor(ast.NodeVisitor):
            def visit_Import(self, node):
                if should_check_repo_pattern:
                    for alias in node.names:
                        name = alias.name.split('.')[-1]
                        if name in FORBIDDEN_IMPORTS:
                            errors.append((node.lineno, f"Forbidden import: '{alias.name}'"))
                self.generic_visit(node)

            def visit_ImportFrom(self, node):
                if should_check_repo_pattern:
                    if node.module and ('sqlalchemy' in node.module or 'repositories' in node.module):
                        for alias in node.names:
                            if alias.name in FORBIDDEN_IMPORTS:
                                errors.append((node.lineno, f"Forbidden import: '{alias.name}' from '{node.module}'"))
                self.generic_visit(node)

            def visit_Call(self, node):
                if should_check_repo_pattern:
                    if isinstance(node.func, ast.Attribute):
                        if isinstance(node.func.value, ast.Name):
                            if node.func.value.id in {'db', 'session'} and node.func.attr in FORBIDDEN_METHODS:
                                errors.append((node.lineno, f"Forbidden direct database session operation: '{node.func.value.id}.{node.func.attr}()'"))
                self.generic_visit(node)

            def visit_FunctionDef(self, node):
                self.check_function_length(node)
                self.generic_visit(node)

            def visit_AsyncFunctionDef(self, node):
                self.check_function_length(node)
                self.generic_visit(node)

            def check_function_length(self, node):
                should_limit = False
                func_type = ""
                if is_endpoint:
                    should_limit = True
                    func_type = "Endpoint function"
                elif is_test and node.name.startswith("test_"):
                    should_limit = True
                    func_type = "Test function"
                    
                if should_limit:
                    start_line = node.decorator_list[0].lineno if node.decorator_list else node.lineno
                    end_line = getattr(node, 'end_lineno', node.lineno)
                    func_len = end_line - start_line + 1
                    if func_len > 50:
                        errors.append((start_line, f"{func_type} '{node.name}' exceeds 50-line limit: {func_len}/50 lines"))

        visitor = LinterVisitor()
        visitor.visit(tree)
        
    return errors

def main():
    # Since this script is now in backend/tests/, its parent dir is the backend root
    backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    
    all_errors = {}
    for root, dirs, files in os.walk(backend_dir):
        if '__pycache__' in root:
            continue
            
        for file in files:
            if not file.endswith('.py'):
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

if __name__ == '__main__':
    main()
