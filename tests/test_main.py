import pytest

from cookiecutter_standalone_pypackage import __main__ as main


def test_main():
    with pytest.raises(SystemExit, match="0"):
        main.main(["--help"])
