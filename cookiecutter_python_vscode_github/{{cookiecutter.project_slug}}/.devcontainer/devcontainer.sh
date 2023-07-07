#!/bin/bash

DEVCONTAINER=$(docker ps --all | grep vsc-{{cookiecutter.project_slug_hyphen}} | awk '{print $1}')
docker stop ${DEVCONTAINER}
docker rm ${DEVCONTAINER}
docker volume rm {{cookiecutter.project_slug_hyphen}}_vscode-server
exit 0