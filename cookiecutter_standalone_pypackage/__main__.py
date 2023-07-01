"""Main module."""

import argparse
import subprocess
import sys
from pathlib import Path

from cookiecutter_standalone_pypackage.version import __version__


def main(argv: list = None):
    """Command-line interface's entrypoint.

    Args:
        argv (list, optional): Argument values. Defaults to None.
    """
    if argv is None:
       argv = sys.argv[1:]
    parser = argparse.ArgumentParser(description="Show cookiecutter's location.", )
    parser.add_argument("--version", action="version", version=__version__)
    parser.parse_args(argv)
    #print(namespace)
    template_dir = Path(__file__).parent
    print(template_dir)
    #subprocess.run(["cookiecutter", template], check=True)
