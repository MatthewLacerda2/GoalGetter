"""The app's clock (#92): one zone, one calendar day, one nightly hour.

Every case here is written in UTC on purpose. The bug was that the answer
depended on the zone the process happened to run in - the container was UTC,
the machine `-03` - so a test that builds its input in the ambient zone would
have passed on the laptop and failed in the container.
"""

from datetime import UTC, date, datetime

from backend.core.clock import (
    APP_TIMEZONE,
    NIGHTLY_RUN_HOUR,
    app_date,
    app_local,
    app_moment,
    as_utc,
    next_nightly_run,
    now,
)


def utc(*args) -> datetime:
    return datetime(*args, tzinfo=UTC)


def test_now_is_timezone_aware_utc():
    assert now().tzinfo is UTC


def test_a_naive_moment_is_read_as_utc():
    assert as_utc(datetime(2026, 9, 22, 1)) == utc(2026, 9, 22, 1)


def test_22_brasilia_is_still_the_21st_though_it_is_01_utc_on_the_22nd():
    assert app_date(utc(2026, 9, 22, 1)) == date(2026, 9, 21)


def test_midnight_utc_is_still_the_previous_evening_for_the_student():
    assert app_local(utc(2026, 9, 22, 0)).hour == 21


def test_an_app_moment_is_that_wall_clock_hour_expressed_in_utc():
    assert app_moment(date(2026, 9, 21), 22) == utc(2026, 9, 22, 1)


def test_the_nightly_run_fires_at_03_brasilia():
    fires = next_nightly_run(utc(2026, 9, 24, 3, 18))  # 00:18 Brasilia, the measured case

    assert fires == utc(2026, 9, 24, 6)
    assert fires.astimezone(APP_TIMEZONE).hour == NIGHTLY_RUN_HOUR


def test_the_nightly_run_rolls_to_the_next_night_once_it_has_passed():
    fires = next_nightly_run(utc(2026, 9, 24, 6))  # exactly 03:00 Brasilia

    assert fires == utc(2026, 9, 25, 6)
    assert fires.astimezone(APP_TIMEZONE).hour == NIGHTLY_RUN_HOUR
