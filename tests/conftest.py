# Import all fixtures so pytest can discover them
pytest_plugins = [
    "tests.fixtures.database",
    "tests.fixtures.auth", 
    "tests.fixtures.gemini",
    "tests.fixtures.users",
    "tests.fixtures.clients",
]