#!/bin/bash

source ./server/config.sh

HIGHLIGHT='\033[0;34m'
NC='\033[0m'

# copy the d3m data into the docker context
echo -e "${HIGHLIGHT}Copying D3M data..${NC}"
mkdir -p ./server/data
cp -r $OUTPUT_DATA_DIR ./server/data
rm -rf ./server/data/d3m
mv ./server/data/output ./server/data/d3m

echo -e "${HIGHLIGHT}Building image ${DOCKER_IMAGE_NAME}...${NC}"

# build the docker image
cd server

CACHEBUSTER_VAL=0
while getopts ":f" opt; do
  case $opt in
    f)
      CACHEBUSTER_VAL=$(date +%s)
      echo "Forcing re-install of primitives"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

docker build --build-arg CACHEBUSTER=$CACHEBUSTER_VAL --build-arg DISTIL_BRANCH=$BRANCH --squash --network=host \
    --tag $DOCKER_REPO/$DOCKER_IMAGE_NAME:${DOCKER_IMAGE_VERSION} \
    --tag $DOCKER_REPO/$DOCKER_IMAGE_NAME:latest .
cd ..


echo -e "${HIGHLIGHT}Done${NC}"
