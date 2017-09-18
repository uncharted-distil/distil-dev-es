#!/bin/bash

source ./server/config.sh
docker push docker.uncharted.software/distil_dev_es:latest
docker push docker.uncharted.software/distil_dev_es:${DOCKER_IMAGE_VERSION}
