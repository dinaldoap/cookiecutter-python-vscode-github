import os
import shutil
from pathlib import Path
from unittest import mock

import pytest

from capgain import __main__ as main


def test_main():
    with pytest.raises(SystemExit, match="0"):
        main.main(["--help"])


def test_parse_args(monkeypatch):
    mock_run_report = mock.Mock()
    monkeypatch.chdir("tests/data")
    monkeypatch.setattr(main, "_run_report", mock_run_report)
    output = _create_output(".")
    expected_config = _create_config(output)
    with pytest.raises(SystemExit, match="0"):
        main.main(
            [
                "report",
                "--change=change",
                "--portfolio=portfolio.xlsx",
                f"--output={str(output)}",
            ]
        )
    mock_run_report.assert_called_once_with(expected_config)


def test_report(tmpdir, monkeypatch):
    base = os.getcwd()
    monkeypatch.chdir(tmpdir)
    shutil.copyfile(f"{base}/tests/data/capgain.ini", f"{tmpdir}/capgain.ini")
    output = Path(tmpdir).joinpath("report.xlsx")
    with pytest.raises(SystemExit, match="0"):
        main.main(
            [
                "report",
                f"--change={base}/tests/data/change",
                f"--portfolio={base}/tests/data/portfolio.xlsx",
                f"--output={str(output)}",
            ]
        )
    assert output.exists()


def _create_output(temp_dir: str):
    output = Path(temp_dir).joinpath("deleteme.xlsx")
    return output


def _create_config(output: Path):
    return {
        "change": Path("change"),
        "portfolio": Path("portfolio.xlsx"),
        "output": output,
        # configuration (capgain.ini)
        "expense_ratio": 0.2,
        # default
        "tax_rate": 0.15,
    }
