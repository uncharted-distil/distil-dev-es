#!/bin/bash

source ./server/config.sh

docker run \
  -t \
  -i \
  --rm \
  --name $DOCKER_IMAGE_NAME \
  -p 9200:9200 \
  $DOCKER_REPO/$DOCKER_IMAGE_NAME:$DOCKER_IMAGE_VERSION