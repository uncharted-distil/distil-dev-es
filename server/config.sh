#!/bin/sh

# name and version of docker image that will be created
DOCKER_IMAGE_NAME=distil_dev_es
DOCKER_IMAGE_VERSION=0.10.4

# datasets to ingest
DATASETS=(185_baseball)

# path to data on local system (ingest from HDFS not currently supported)
HOST_DATA_DIR=~/data/d3m

# path to data in the docker container
CONTAINER_DATA_DIR=/input/d3m
