#!/bin/bash

## Linux tools ##
# Clean bashrc and bash aliases configurations
sed --in-place --expression '/# >>> venv-init >>>/,/*# <<< venv-init <<</d' ~/.bashrc ~/.bash_aliases

# Config bash aliases
cat << EOF >> ~/.bash_aliases
# >>> venv-init >>>
# current folder virtual environment activation
alias activate="source .venv/bin/activate"
# <<< venv-init <<<
EOF

# Config bashrc
cat << EOF >> ~/.bashrc
# >>> venv-init >>>
code --install-extension ms-python.isort > /dev/null
# activate virtual environment
activate
# <<< venv-init <<<
EOF

## Python tools ##
# Activate virtual environment
source .venv/bin/activate

# Config pre-commit
pre-commit install --overwrite --hook-type=pre-commit --hook-type=pre-push
