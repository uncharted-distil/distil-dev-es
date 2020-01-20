#!/bin/bash

source ./config.sh

GEOCODED_OUTPUT_PATH=geocoded/tables/learningData.csv
OUTPUT_SCHEMA=geocoded/datasetDoc.json
CLASSIFICATION_OUTPUT_PATH=classification.json
IMPORTANCE_OUTPUT=importance.json
SUMMARY_MACHINE_OUTPUT=summary-machine.json
METADATA_INDEX=datasets
ES_ENDPOINT=http://127.0.0.1:9200
SUMMARY_OUTPUT_PATH=summary.txt

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Ingesting $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./distil-ingest \
        --es-endpoint="$ES_ENDPOINT" \
        --es-metadata-index="$METADATA_INDEX" \
        --es-dataset-prefix="d_" \
        --dataset-folder="$DATASET" \
        --schema="$CONTAINER_DATA_DIR/${DATASET}/$OUTPUT_SCHEMA" \
        --dataset="$CONTAINER_DATA_DIR/${DATASET}/$GEOCODED_OUTPUT_PATH" \
        --classification="$CLASSIFICATION_OUTPUT_PATH" \
        --summary="$SUMMARY_OUTPUT_PATH" \
        --summary-machine="$SUMMARY_MACHINE_OUTPUT" \
        --importance="$IMPORTANCE_OUTPUT"
done
