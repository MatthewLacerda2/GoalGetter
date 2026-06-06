import pytest

# Import all fixtures so pytest can discover them
pytest_plugins = [
    "backend.tests.fixtures.database",
    "backend.tests.fixtures.auth", 
    "backend.tests.fixtures.users",
    "backend.tests.fixtures.clients",
]