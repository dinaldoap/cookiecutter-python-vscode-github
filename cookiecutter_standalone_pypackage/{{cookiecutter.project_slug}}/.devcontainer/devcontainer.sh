#!/bin/bash

DEVCONTAINER=$(docker ps --all | grep vsc-capgain | awk '{print $1}')
docker stop ${DEVCONTAINER}
docker rm ${DEVCONTAINER}
docker volume rm capgain_vscode-server
exit 0