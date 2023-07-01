"""Main module."""
import configparser
import sys
from pathlib import Path
from typing import Optional

import typer
from typing_extensions import Annotated

from capgain.pipeline import Report
from capgain.version import __version__

app = typer.Typer()


def _add_config(argv: list, file: str = "capgain.ini"):
    command_depth = 1
    command_index = command_depth - 1
    if len(argv) < command_depth:
        return argv
    command = argv[command_index]
    command_config = f"{command}_args"
    config_parser = configparser.ConfigParser()
    config_parser.read(file)
    configv = (
        dict(config_parser["capgain"]) if config_parser.has_section("capgain") else {}
    )
    configv = configv[command_config] if command_config in configv else ""
    configv = configv.split()
    return argv[:command_depth] + configv + argv[command_depth:]


def main(argv: list = None):
    """Command-line interface's entrypoint.

    Args:
        argv (list, optional): Argument values. Defaults to None.

    Raises:
        RuntimeError: When subcommand value is not expected.
    """
    if argv is None:
        argv = sys.argv[1:]
    configv_argv = _add_config(argv)
    app(configv_argv)


def _version_callback(value: bool):
    if value:
        print(__version__)
        raise typer.Exit()


@app.callback()
def capgain(
    _: Annotated[
        Optional[bool],
        typer.Option(
            "-V",
            "--version",
            help="Show version and exit.",
            callback=_version_callback,
            is_eager=True,
        ),
    ] = None,
):
    """Capgain: Calculator of capital gain and accumulated wealth for brazilian
    investors."""


@app.command()
def report(
    change: Annotated[
        Path,
        typer.Option("--change", "-c", help="Directory with change history files."),
    ] = Path("change"),
    portfolio: Annotated[
        Path,
        typer.Option(
            "--portfolio", "-p", help="Portfolio with target percentages per ticker."
        ),
    ] = Path("portfolio.xlsx"),
    output: Annotated[
        Path,
        typer.Option(
            "--output", "-o", help="Output with changes to be done per ticker."
        ),
    ] = Path("output.xlsx"),
    expense_ratio: Annotated[
        float,
        typer.Option(
            "--expense-ratio", "-e", help="Expense ratio.", show_default="0.03%"
        ),
    ] = 0.0003,
    tax_rate: Annotated[
        float,
        typer.Option("--tax-rate", "-x", help="Tax rate.", show_default="15.0%"),
    ] = 0.15,
):
    """Generate report with capital gain and accumulated wealth.

    The portfolio spreadsheet (portolio.xlsx) and a change history
    spreadsheet (change.xlsx) must be passed as input to the basic
    usage. The expected column layout is as follows:\n
    Portfolio:\n                 (1) Name: str, description of the
    ticker, e.g., iShares Core S&P 500 ETF.\n                 (2)
    Ticker: str, ticker name, e.g., IVV.\n                 (3) Target:
    float, target percentage for the ticker, e.g., 40%.\n
    Change history:\n                 (1) Data do Negociação: str,
    transaction date, e.g., 01/02/2021.\n                 (2) Código de
    Negociação: str, ticker name, e.g., IVV.\n                 (3)
    Quantidade: int, number of units exchanged, e.g., 10.\n
    (4) Preço: float, ticker price, e.g., 40.0.\n
    Additional columns in the spreadsheet are ignored.\n
    """
    config = {
        "change": change,
        "portfolio": portfolio,
        "output": output,
        "expense_ratio": expense_ratio,
        "tax_rate": tax_rate,
    }
    _run_report(config)


def _run_report(config: dict):
    Report(config=config).run()


if __name__ == "__main__":
    main()
