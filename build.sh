#!/bin/bash

source ./server/config.sh

HIGHLIGHT='\033[0;34m'
NC='\033[0m'

echo -e "${HIGHLIGHT}Getting distil-ingest..${NC}"

# get distil-ingest and force a static rebuild of it so that it can run on Alpine
go get -u -v github.com/unchartedsoftware/distil-ingest/cmd/distil-merge
go get -u -v github.com/unchartedsoftware/distil-ingest/cmd/distil-classify
go get -u -v github.com/unchartedsoftware/distil-ingest/cmd/distil-rank
go get -u -v github.com/unchartedsoftware/distil-ingest/cmd/distil-ingest
go get -u -v github.com/unchartedsoftware/distil-ingest/cmd/distil-summary
go get -u -v github.com/unchartedsoftware/distil-ingest/cmd/distil-featurize
go get -u -v github.com/unchartedsoftware/distil-ingest/cmd/distil-cluster
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -a github.com/unchartedsoftware/distil-ingest/cmd/distil-merge
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -a github.com/unchartedsoftware/distil-ingest/cmd/distil-classify
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -a github.com/unchartedsoftware/distil-ingest/cmd/distil-rank
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -a github.com/unchartedsoftware/distil-ingest/cmd/distil-ingest
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -a github.com/unchartedsoftware/distil-ingest/cmd/distil-summary
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -a github.com/unchartedsoftware/distil-ingest/cmd/distil-featurize
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -a github.com/unchartedsoftware/distil-ingest/cmd/distil-cluster
mv distil-merge ./server
mv distil-classify ./server
mv distil-rank ./server
mv distil-ingest ./server
mv distil-summary ./server
mv distil-featurize ./server
mv distil-cluster ./server

echo -e "${HIGHLIGHT}Copying D3M data..${NC}"

# copy the d3m data into the docker context
mkdir -p ./server/data/d3m
for DATASET in "${DATASETS_SEED[@]}"
do
    echo "cp $HOST_DATA_DIR/$DATASET into ./server/data/d3m/$DATASET"
    cp -r $HOST_DATA_DIR/$DATASET ./server/data/d3m
done

for DATASET in "${DATASETS_EVAL[@]}"
do
    echo "cp $HOST_DATA_DIR_EVAL/$DATASET into ./server/data/d3m/$DATASET"
    cp -r $HOST_DATA_DIR_EVAL/$DATASET ./server/data/d3m
done

# start pipeline runner container
docker run -d --rm --name pipeline_runner -p 50051:50051 --env D3MOUTPUTDIR=/output --env STATIC_RESOURCE_PATH=/static_resources -v "/home/ubuntu/datasets:/home/ubuntu/datasets" -v /input:/input -v /output:/output -v /static_resources:/static_resources docker.uncharted.software/distil-pipeline-runner:latest
echo "Waiting for the pipeline runner to be available..."
sleep 10

echo -e "${HIGHLIGHT}Building image ${DOCKER_IMAGE_NAME}...${NC}"

# build the docker image
cd server

docker build --squash --no-cache --network=host \
    --tag docker.uncharted.software/$DOCKER_IMAGE_NAME:${DOCKER_IMAGE_VERSION} \
    --tag docker.uncharted.software/$DOCKER_IMAGE_NAME:latest .
cd ..

# stop pipeline runner
docker stop pipeline_runner

echo -e "${HIGHLIGHT}Done${NC}"
