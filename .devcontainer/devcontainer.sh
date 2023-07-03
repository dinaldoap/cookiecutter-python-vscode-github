#!/bin/bash

DEVCONTAINER=$(docker ps --all | grep vsc-cookiecutter-standalone-pypackage | awk '{print $1}')
docker stop ${DEVCONTAINER}
docker rm ${DEVCONTAINER}
docker volume rm cookiecutter-standalone-pypackage_vscode-server
exit 0