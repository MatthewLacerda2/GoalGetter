"""Each kind on the hub map fails outside its hub and passes inside it (#231).

A case is written the way the rule could be dodged - an alias, a subclass of a
subclass, a qualified name - because the rule reads what the code does, never
what it is called (#212).
"""

import textwrap

import pytest

from backend.tests.backend_linter import check_source

SERVICE = "backend/services/example.py"

# kind -> (its home, code that defines or uses the kind)
OUTSIDE_ITS_HUB = {
    "Pydantic model": (
        "backend/schemas/example.py",
        """
        from pydantic import BaseModel

        class Answer(BaseModel):
            text: str
        """,
    ),
    "Pydantic model, aliased module": (
        "backend/services/gemini/example/schema.py",
        """
        import pydantic as pd

        class Answer(pd.BaseModel):
            text: str
        """,
    ),
    "Pydantic model, through a local subclass": (
        "backend/schemas/example.py",
        """
        from pydantic import BaseModel as Shape

        class Base(Shape):
            pass

        class Answer(Base):
            text: str
        """,
    ),
    "Pydantic model, extending a schema": (
        "backend/schemas/example.py",
        """
        from backend.schemas.goal import GoalResponse

        class RicherGoal(GoalResponse):
            extra: int
        """,
    ),
    "Pydantic model, built at runtime": (
        "backend/schemas/example.py",
        """
        import pydantic

        Answer = pydantic.create_model("Answer", text=(str, ...))
        """,
    ),
    "Settings": (
        "backend/core/config.py",
        """
        from pydantic_settings import BaseSettings

        class More(BaseSettings):
            FLAG: bool = False
        """,
    ),
    "Router": (
        "backend/api/v1/endpoints/example.py",
        """
        from fastapi import APIRouter

        router = APIRouter()
        """,
    ),
    "Route on the app": (
        "backend/api/example.py",
        """
        import fastapi

        app = fastapi.FastAPI()

        @app.get("/ping")
        async def ping():
            return "pong"
        """,
    ),
    "ORM table": (
        "backend/models/example.py",
        """
        from backend.models.base import Base

        class Note(Base):
            pass
        """,
    ),
    "ORM table, by its table name": (
        "backend/models/example.py",
        """
        class Note:
            __tablename__ = "notes"
        """,
    ),
    "HTTP error": (
        "backend/core/errors/example.py",
        """
        from fastapi import HTTPException

        def refuse():
            raise HTTPException(status_code=404, detail="gone")
        """,
    ),
    "HTTP error, from starlette": (
        "backend/core/errors/example.py",
        """
        import starlette.exceptions as se

        def refuse():
            raise se.HTTPException(404)
        """,
    ),
    "Environment read": (
        "backend/core/config.py",
        """
        import os

        KEY = os.environ.get("GEMINI_API_KEY")
        """,
    ),
    "Environment read, imported by name": (
        "backend/core/config.py",
        """
        from os import getenv as env

        KEY = env("GEMINI_API_KEY")
        """,
    ),
    "Wall clock": (
        "backend/core/clock.py",
        """
        from datetime import UTC, datetime

        def stamp():
            return datetime.now(UTC)
        """,
    ),
    "Wall clock, through the module": (
        "backend/core/clock.py",
        """
        import datetime as dt
        import time

        def stamp():
            return dt.date.today(), time.time()
        """,
    ),
}

NOT_A_HUB_KIND = {
    "a Pydantic error, caught": """
        from pydantic import ValidationError

        def parse(model, text):
            try:
                return model.model_validate_json(text)
            except ValidationError:
                return None
        """,
    "a dataclass": """
        from dataclasses import dataclass

        @dataclass
        class Pick:
            question_id: int
        """,
    "ApiError, the errors hub's door": """
        from backend.core.errors import ApiError, ErrorCode

        def refuse():
            raise ApiError(ErrorCode.NO_ACTIVE_GOAL)
        """,
    "a dict's get on something called app": """
        def route(app: dict, path: str):
            return app.get(path)
        """,
    "an elapsed time, measured": """
        import time

        def elapsed(start):
            return time.monotonic() - start
        """,
    "the settings, read": """
        from backend.core.config import settings

        KEY = settings.GEMINI_API_KEY
        """,
}


def violations(code: str, path: str = SERVICE) -> list:
    return check_source(textwrap.dedent(code), path)


CASES = [pytest.param(home, code, id=kind) for kind, (home, code) in OUTSIDE_ITS_HUB.items()]


@pytest.mark.parametrize(("home", "code"), CASES)
def test_the_kind_outside_its_hub_fails(home, code):
    assert any("outside its hub" in message for _, message in violations(code))


@pytest.mark.parametrize(("home", "code"), CASES)
def test_the_same_code_in_its_hub_passes(home, code):
    assert violations(code, home) == []


@pytest.mark.parametrize("code", NOT_A_HUB_KIND.values(), ids=NOT_A_HUB_KIND.keys())
def test_what_only_looks_like_a_hub_kind_passes(code):
    assert violations(code) == []


def test_a_test_builds_whatever_fake_it_needs():
    fake = OUTSIDE_ITS_HUB["Pydantic model"][1]
    assert violations(fake, "backend/tests/test_services/test_example.py") == []
