#!/bin/sh

# name and version of docker image that will be created
DOCKER_IMAGE_NAME=distil_dev_es
DOCKER_IMAGE_VERSION=0.8.1

# datasets to ingest
DATASETS=(26_radon_seed 32_wikiqa 60_jester 185_baseball 196_autoMpg 313_spectrometer 38_sick 4550_MiceProtein)

# path to data on local system (ingest from HDFS not currently supported)
HOST_DATA_DIR=~/data/d3m_new

# path to data in the docker container
CONTAINER_DATA_DIR=/input/d3m
