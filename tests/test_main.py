import subprocess as sp
from pathlib import Path

import pytest
from pytest import MonkeyPatch

from cookiecutter_standalone_pypackage import __main__ as main


def test_main():
    with pytest.raises(SystemExit, match="0"):
        main.main(["--help"])


def test_show():
    expected_template_path = Path(__file__).parent.parent.joinpath(
        "cookiecutter_standalone_pypackage"
    )
    actual_template_path = Path(_show())

    assert expected_template_path == actual_template_path


def test_bake(tmp_path: Path, monkeypatch: MonkeyPatch):
    template_dir = _show()
    monkeypatch.chdir(tmp_path)
    sp.run(["cookiecutter", template_dir, "--no-input"], check=True)
    assert tmp_path.joinpath(
        "cookiecutter_standalone_pypackage/cookiecutter_standalone_pypackage/__main__.py"
    ).exists(), "__main__.py was not generated."


def _show():
    return sp.run(
        ["cookiecutter-standalone-pypackage"],
        check=True,
        text=True,
        capture_output=True,
    ).stdout.strip()
