#!/bin/bash

# Create virtual environment and install dependencies
python -m venv --clear --prompt={{cookiecutter.project_slug_hyphen}} .venv
source .venv/bin/activate
make install
