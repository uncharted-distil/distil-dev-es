#!/bin/bash

source ./server/config.sh
docker login $DOCKER_REPO
docker push $DOCKER_REPO/distil_dev_es:latest
docker push $DOCKER_REPO/distil_dev_es:${DOCKER_IMAGE_VERSION}
docker logout $DOCKER_REPO
