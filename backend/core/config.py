"""The settings object: the one thing in the backend that reads the environment.

Everything configurable is a field here, and code reads it at call time as
`settings.FIELD` - never through a copy taken into a module global at import
time, which a test that patches `settings` would never reach. The
environment wins over the root `.env`, which pydantic-settings reads by itself:
nothing else calls `load_dotenv` or reads `os.environ`.
"""

from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

# Calculate the root path of the project (3 levels up from backend/core/config.py)
ROOT_DIR = Path(__file__).resolve().parent.parent.parent
ROOT_ENV = ROOT_DIR / ".env"


class Settings(BaseSettings):
    GEMINI_API_KEY: str
    SECRET_KEY: str
    GOOGLE_CLIENT_ID: str = ""
    # YouTube Data API v3 key, used to confirm that recommended channels/videos
    # really exist and have a profile picture. Empty = YouTube links are dropped.
    YOUTUBE_API_KEY: str = ""
    # Dev only: turns on POST /auth/dev-login (a fictitious sign-in, no Google)
    # and lets loopback/Tailscale dev origins through CORS. Off in production:
    # the route then answers 404 as if it did not exist. See backend/core/cors.py.
    DEV_LOGIN: bool = False

    DATABASE_URL: str
    # The run's disposable test database, set by tools/test-db.sh for the length
    # of `make back-test` / `make back-migrations`. Nothing else sets it,
    # and the gates never read it from .env: the script's value wins.
    TEST_DATABASE_URL: str | None = None

    # The connection pool of ONE process (backend/core/database.py), sized so
    # that every process together fits under Postgres's `max_connections` (#219).
    # The server runs with the default, 100: docker-compose.yml does not raise
    # it. Each process may open at most pool + overflow = 5 + 5 = 10, and these
    # are the processes that reach that one server:
    #
    #   the API, `--workers 4` in docker-compose.yml   4 x 10 = 40
    #   `nightly`                                               10
    #   the preview backend on 8001 (`make preview`,
    #   one worker, its own database on the same server)        10
    #   one process run by hand (`make nightly`,
    #   `make embeddings`, the seeder behind `make claude`)     10
    #   `migrate` (alembic on a NullPool: one connection)        1
    #                                                         ----
    #                                                           71 of 100
    #
    # The other 29 are for `psql` and whatever nobody foresaw; they include the
    # 3 slots Postgres keeps for superusers. Raise a number here, or the worker
    # count in docker-compose.yml, and this sum has to be redone:
    # backend/tests/test_core/test_database_pool.py redoes it and fails first.
    #
    # Ten per worker is plenty here: a request holds a connection for
    # milliseconds, except across a Gemini call - and the tutor, the one a
    # student waits on most, gives it back before calling (endpoints/tutor.py).
    DB_POOL_SIZE: int = 5
    DB_MAX_OVERFLOW: int = 5

    # The generation models. Premium where one answer shapes a whole goal (the
    # validation, the study plan, the student context); fast for what runs often
    # and is judged by the next answer (lessons, the placement, the chat, the
    # resource search). The embedding model is not here: it is bound to the
    # width of every vector column (backend/core/vectors.py), so changing it is
    # a migration, not a setting.
    GEMINI_FAST_MODEL: str = "gemini-3.5-flash-lite"
    GEMINI_PREMIUM_MODEL: str = "gemini-3.8-flash"

    # How many questions one Gemini call is asked for. **The size of a batch, not
    # of a lesson** (#135): a lesson is two minutes, and how many questions that is
    # comes from the student's own answering pace (six to twelve,
    # services/lessons/pacing.py).
    #
    # Eight, in the user's own words: "pedir exatamente 8 e uma boa, nao sao
    # perguntas demais nem de menos; pedir demais pode diminuir a performance, ainda
    # mais quando nao temos contexto suficiente sobre o usuario". It is a fixed
    # number, not a gap to fill, because the decision to generate is not about how
    # full the bank is (services/lessons/generation.py).
    QUESTIONS_PER_GENERATION: int = 8

    # The placement (the user, 2026-09-26): what a new goal is given right after
    # onboarding, and how many answers it must hold before the nightly run buys it
    # anything more. One number for both on purpose.
    #
    # Eighteen is three lessons at the six-question floor - *"creio que ajuda bem a
    # definir o quanto o usuário sabe"*. And until he has answered that many (answers,
    # not distinct questions: one he answered twice counts twice), the app has not
    # measured him yet, so there is nothing to write the next batch from.
    PLACEMENT_SIZE: int = 18

    model_config = SettingsConfigDict(
        case_sensitive=True, env_file=str(ROOT_ENV), env_file_encoding="utf-8", extra="ignore"
    )


settings = Settings()
