#!/bin/bash

DEVCONTAINER=$(docker ps --all | grep vsc-cookiecutter-python-package | awk '{print $1}')
docker stop ${DEVCONTAINER}
docker rm ${DEVCONTAINER}
docker volume rm cookiecutter-python-package_vscode-server
exit 0