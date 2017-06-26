#!/bin/bash

source ./config.sh

echo "**************"
echo $DATA_DIR
echo $DATASETS

for dataset in "${DATASETS[@]}"
do
    ./distil-ingest -es-endpoint http://localhost:9200 -es-index $dataset -clear-existing -dataset-path /input/$dataset
done
