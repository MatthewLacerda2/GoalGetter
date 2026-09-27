"""The OpenAPI snapshot `make back-build` keeps (#213): a stale copy is
rewritten and reported, a current one is left alone."""

from backend.tools.build_smoke import render, write_snapshot

SCHEMA = {"openapi": "3.1.0", "paths": {"/api/v1/goals": {"get": {}}}}


def test_a_missing_snapshot_is_written_and_reported_stale(tmp_path):
    path = tmp_path / "openapi.json"

    assert write_snapshot(SCHEMA, path) is False
    assert path.read_text(encoding="utf-8") == render(SCHEMA)


def test_a_current_snapshot_passes_untouched(tmp_path):
    path = tmp_path / "openapi.json"
    path.write_text(render(SCHEMA), encoding="utf-8")

    assert write_snapshot(SCHEMA, path) is True


def test_a_changed_api_rewrites_the_snapshot_and_fails(tmp_path):
    path = tmp_path / "openapi.json"
    path.write_text(render(SCHEMA), encoding="utf-8")
    moved = {"openapi": "3.1.0", "paths": {"/api/v1/goals": {"post": {}}}}

    assert write_snapshot(moved, path) is False
    assert '"post"' in path.read_text(encoding="utf-8")
