#!/bin/bash

source ./config.sh

SCHEMA=/datasetDoc.json
HAS_HEADER=1
MERGED_OUTPUT_PATH=merged/tables/learningData.csv
OUTPUT_SCHEMA=merged/datasetDoc.json
CLASSIFICATION_OUTPUT_PATH=classification.json
IMPORTANCE_OUTPUT=importance.json
SUMMARY_MACHINE_OUTPUT=summary-machine.json
METADATA_INDEX=datasets
ES_ENDPOINT=http://127.0.0.1:9200
SUMMARY_OUTPUT_PATH=summary.txt
TYPE_SOURCE=classification

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Ingesting $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./distil-ingest \
        --es-endpoint="$ES_ENDPOINT" \
        --es-metadata-index="$METADATA_INDEX" \
        --es-data-index="$DATASET" \
        --es-dataset-prefix="d_" \
        --schema="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$OUTPUT_SCHEMA" \
        --dataset="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$MERGED_OUTPUT_PATH" \
        --classification="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$CLASSIFICATION_OUTPUT_PATH" \
        --summary="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$SUMMARY_OUTPUT_PATH" \
        --summary-machine="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$SUMMARY_MACHINE_OUTPUT" \
        --importance="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$IMPORTANCE_OUTPUT" \
        --type-source="$TYPE_SOURCE" \
        --clear-existing
done
