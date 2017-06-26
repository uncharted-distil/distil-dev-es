#!/bin/bash

source ./server/config.sh

HIGHLIGHT='\033[0;34m'
NC='\033[0m'


echo -e "${HIGHLIGHT}Getting veldt-ingest..${NC}"

# get veldt-ingest and force a static rebuild of it so that it can run on Alpine
go get -u -v github.com/unchartedsoftware/distil-ingest
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -v -a github.com/unchartedsoftware/distil-ingest
mv distil-ingest ./server


echo -e "${HIGHLIGHT}Copying D3M data..${NC}"

# copy the d3m data into the docker context
mkdir -p ./server/data
for dataset in "${DATASETS[@]}"
do
    echo "cp $DATA_PATH/$dataset into ./server/data/$dataset"
    cp -r $DATA_PATH/$dataset ./server/data
done


echo -e "${HIGHLIGHT}Building image ${DOCKER_IMAGE_NAME}...${NC}"

# build the docker image
cd server
docker build -t docker.uncharted.software/$DOCKER_IMAGE_NAME:${DOCKER_IMAGE_VERSION} .
cd ..
echo -e "${HIGHLIGHT}Done${NC}"
