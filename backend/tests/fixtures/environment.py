"""The settings the suite runs on: these, and nothing the machine happens to hold (#207).

`backend.core.config` reads the environment and then the root `.env`. For the
app that is the point; for the tests it was a hole. The local gate mounts the
worktree, `.env` included, so it read the developer's real values - and twice in
one night a branch was green here and red in CI, which has no `.env`: a real
SECRET_KEY long enough where CI's was not (#260), a real GOOGLE_CLIENT_ID where
CI had none (#264).

So this module, the first plugin the root conftest loads - before anything
imports the settings - pins **every** setting the suite depends on, removes any
other setting from the environment so its default applies, and then rebuilds
the one `settings` object from the environment alone, no `.env`. What a test sees is exactly
`PINNED` plus the defaults in `config.py`, on every machine. The gate goes one
further: `make back-test` hides `.env` from its container behind an empty file,
so not even the read the import makes - discarded here - sees the real one.

The exception is `TEST_DATABASE_URL`, which `tools/test-db.sh` hands the run and
nothing else sets. And the live suite (`--live`) gets back the two API keys it
exists to spend - from the environment, else from `.env`, the order the app
reads them in.
"""

import os

import pytest
from dotenv import dotenv_values

# Resolves nowhere (RFC 2606): a test that opens the app's own session instead
# of the test's fails loudly - see network.py.
UNREACHABLE_HOST = "database-url-is-not-for-tests.invalid"

PINNED = {
    "DATABASE_URL": f"postgresql+asyncpg://nobody:nothing@{UNREACHABLE_HOST}/none",
    # 40 bytes: PyJWT warns under 32 for HS256, and a warning fails the run (#206).
    "SECRET_KEY": "the-test-suite-signs-with-this-key-only!",
    "GEMINI_API_KEY": "the-test-suite-has-no-gemini-key",
    "GOOGLE_CLIENT_ID": "the-test-suite.apps.googleusercontent.com",
    "YOUTUBE_API_KEY": "",
    "DEV_LOGIN": "false",
}
# Handed to the run, never read from a file (tools/test-db.sh).
FROM_THE_RUN = {"TEST_DATABASE_URL"}
# What the live suite spends, and so the only settings it takes back.
LIVE_KEYS = ("GEMINI_API_KEY", "YOUTUBE_API_KEY")

ORIGINAL = {name: os.environ[name] for name in PINNED if name in os.environ}
os.environ.update(PINNED)

from backend.core.config import ROOT_ENV, Settings, settings  # noqa: E402 - after the pins

for name in Settings.model_fields.keys() - PINNED.keys() - FROM_THE_RUN:
    os.environ.pop(name, None)
# The one object every module holds, rebuilt in place from the environment alone.
UNFILED = Settings(_env_file=None)
for name in Settings.model_fields:
    setattr(settings, name, getattr(UNFILED, name))


@pytest.hookimpl
def pytest_configure(config):
    if config.getoption("--live"):
        found = {**dotenv_values(ROOT_ENV), **ORIGINAL}
        for name in LIVE_KEYS:
            setattr(settings, name, found.get(name) or "")
