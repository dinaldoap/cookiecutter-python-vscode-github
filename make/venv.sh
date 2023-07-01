#!/bin/bash

# Create virtual environment and install dependencies
python -m venv --clear --prompt=cookiecutter-standalone-pypackage .venv
source .venv/bin/activate
make install
