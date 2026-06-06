#!/bin/bash
set -e

# Make sure we are at the repository root
cd "$(dirname "$0")"

echo "Generating openapi.json from FastAPI app..."
# Run Python to dump the openapi schema
if [ -d ".venv" ]; then
    PYTHON_CMD=".venv/bin/python"
elif [ -d "../GoalGetter/.venv" ]; then
    # Fallback to the parallel worktree venv if needed
    PYTHON_CMD="../GoalGetter/.venv/bin/python"
else
    PYTHON_CMD="python"
fi

PYTHONPATH=. $PYTHON_CMD -c "import json; from backend.main import app; print(json.dumps(app.openapi()))" > openapi.json

# Check generator availability and run it
if command -v openapi-generator-cli >/dev/null 2>&1; then
    echo "Generating Dart client SDK using local openapi-generator-cli..."
    openapi-generator-cli generate -i ./openapi.json -g dart -o ./client_sdk
elif command -v docker >/dev/null 2>&1; then
    echo "Local openapi-generator-cli not found. Falling back to Docker-based generator..."
    docker run --rm -v "${PWD}:/local" openapitools/openapi-generator-cli generate \
        -i /local/openapi.json \
        -g dart \
        -o /local/client_sdk
else
    echo "Error: Neither local 'openapi-generator-cli' nor 'docker' was found."
    echo "Please install openapi-generator-cli or Docker to generate the client SDK."
    exit 1
fi

echo "Client SDK generated successfully in ./client_sdk"
