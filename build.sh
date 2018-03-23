#!/bin/bash
set -e
# This helper script iterates through the Golang apps and builds docker images
# for each of the services

REVISION=`git rev-parse --short=2 HEAD`

echo "Building Pharos app"
DOCKER_IMG_TAG="aptrust/pharos"
    docker build -t ${DOCKER_IMG_TAG}:latest -t ${DOCKER_IMG_TAG}:${REVISION} .
