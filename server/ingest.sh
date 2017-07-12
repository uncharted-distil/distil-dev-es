#!/bin/bash

source ./config.sh

# merge datasets
for DATASET in "${DATASETS[@]}"
do
    echo "********************************************************************************"
    echo "Merging datasets in $CONTAINER_DATA_DIR/$DATASET into $CONTAINER_DATA_DIR/$DATASET/$MERGED_OUTPUT"
    echo "********************************************************************************"
    ./distil-merge \
        --schema="$CONTAINER_DATA_DIR/$DATASET/$SCHEMA" \
        --training-data="$CONTAINER_DATA_DIR/$DATASET/$TRAINING_DATA" \
        --training-targets="$CONTAINER_DATA_DIR/$DATASET/$TRAINING_TARGETS" \
        --output="$CONTAINER_DATA_DIR/$DATASET/$MERGED_OUTPUT"
done

# ingest datasets
for DATASET in "${DATASETS[@]}"
do
    echo "********************************************************************************"
    echo "Ingesting $CONTAINER_DATA_DIR/$DATASET/$MERGED_OUTPUT into $ES_ENDPOINT/$DATASET"
    echo "********************************************************************************"
    ./distil-ingest \
        --es-endpoint="$ES_ENDPOINT" \
        --es-index="$DATASET" \
        --schema="$CONTAINER_DATA_DIR/$DATASET/$SCHEMA" \
        --dataset="$CONTAINER_DATA_DIR/$DATASET/$MERGED_OUTPUT" \
        --clear-existing
done
