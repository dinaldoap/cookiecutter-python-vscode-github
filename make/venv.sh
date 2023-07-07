#!/bin/bash

# Create virtual environment and install dependencies
python -m venv --clear --prompt=cookiecutter-python-vscode-github .venv
source .venv/bin/activate
make install
