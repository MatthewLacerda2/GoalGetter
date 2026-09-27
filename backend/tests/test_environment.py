"""The suite runs on the settings it pins, and on nothing the machine holds.

A local run that reads the developer's `.env` goes green on what is red in CI,
which has none (#260, #264). `fixtures/environment.py` closes
that; this is what says it stayed closed.
"""

from pydantic import TypeAdapter

from backend.core.config import Settings, settings
from backend.tests.fixtures.environment import FROM_THE_RUN, PINNED


def test_every_setting_is_the_pinned_value_or_its_default():
    """Worked out from the class alone - no environment, no file - so a value
    that leaked in from `.env` or the shell is a difference here, whichever
    setting it is. A new required setting nobody pinned is one too."""
    fields = Settings.model_fields
    expected = {name: field.default for name, field in fields.items() if not field.is_required()}
    expected |= {
        name: TypeAdapter(fields[name].annotation).validate_python(value)
        for name, value in PINNED.items()
    }

    assert settings.model_dump(exclude=FROM_THE_RUN) == {
        name: value for name, value in expected.items() if name not in FROM_THE_RUN
    }
