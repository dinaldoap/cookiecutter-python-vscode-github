"""Main module."""

import argparse
import subprocess as sp  # nosec
import sys
from pathlib import Path

from cookiecutter_python_vscode_github.version import __version__


def main(argv: list = None):
    """Command-line interface's entrypoint.

    Args:
        argv (list, optional): Argument values. Defaults to None.
    """
    if argv is None:
        argv = sys.argv[1:]
    parser = argparse.ArgumentParser(
        description="Show template's directory.",
    )
    parser.add_argument("--version", action="version", version=__version__)
    parser.parse_args(argv)
    composition_path = Path(__file__).parent.joinpath("cookie-composer.yaml")
    sp.run(  # nosec
        [
            "cookie-composer",
            "create",
            f"--checkout={__version__}",
            composition_path,
        ],
        check=True,
    )
