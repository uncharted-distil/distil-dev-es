#!/bin/bash

source ./config.sh

SCHEMA=/datasetDoc.json
OUTPUT_PATH=features/
FEATURE_OUTPUT_DATA=features/features.csv
FEATURE_OUTPUT_SCHEMA=featuresDatasetDoc.json
DATASET_FOLDER_SUFFIX=_dataset
HAS_HEADER=1
FEATURIZE_FUNCTION=fileupload
REST_ENDPOINT=HTTP://10.108.4.42:5002
DATA_SERVER=HTTP://10.108.4.104

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Featurizing $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./distil-featurize \
        --rest-endpoint="$REST_ENDPOINT" \
        --featurize-function="$FEATURIZE_FUNCTION" \
        --dataset="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN" \
        --media-path="$DATA_SERVER/${DATASET}" \
        --schema="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$SCHEMA" \
        --output="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN" \
        --output-data="$FEATURE_OUTPUT_DATA" \
        --output-schema="$FEATURE_OUTPUT_SCHEMA" \
        --has-header=$HAS_HEADER
done

MERGED_OUTPUT_PATH=tables/merged.csv
MERGED_OUTPUT_HEADER_PATH=tables/mergedHeader.csv
OUTPUT_SCHEMA=mergedDatasetDoc.json
MERGE_HAS_HEADER=1

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Merging $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./distil-merge \
        --schema="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$FEATURE_OUTPUT_SCHEMA" \
        --data="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$FEATURE_OUTPUT_DATA" \
        --raw-data="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/" \
        --output-path="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$MERGED_OUTPUT_PATH" \
        --output-path-relative="$MERGED_OUTPUT_PATH" \
        --output-path-header="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$MERGED_OUTPUT_HEADER_PATH" \
        --output-schema-path="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$OUTPUT_SCHEMA" \
        --has-header=$MERGE_HAS_HEADER
done

CLASSIFICATION_OUTPUT_PATH=classification.json
REST_ENDPOINT=http://127.0.0.1:5000
CLASSIFICATION_FUNCTION=fileUpload

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Classifying $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./distil-classify \
        --rest-endpoint="$REST_ENDPOINT" \
        --classification-function="$CLASSIFICATION_FUNCTION" \
        --dataset="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$MERGED_OUTPUT_PATH" \
        --output="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$CLASSIFICATION_OUTPUT_PATH"
done

IMPORTANCE_OUTPUT=importance.json
RANKING_REST_ENDPOINT=HTTP://127.0.0.1:5001
RANKING_FUNCTION=pca
NUMERIC_OUTPUT_SUFFIX=_numeric.csv
TYPE_SOURCE=classification
ROW_LIMIT=1000

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Ranking $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./distil-rank \
        --schema="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$OUTPUT_SCHEMA" \
        --dataset="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$MERGED_OUTPUT_PATH" \
        --rest-endpoint="$RANKING_REST_ENDPOINT" \
        --ranking-function="$RANKING_FUNCTION" \
        --ranking-output="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$DATASET$NUMERIC_OUTPUT_SUFFIX" \
        --classification="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$CLASSIFICATION_OUTPUT_PATH" \
        --has-header=$HAS_HEADER \
        --row-limit=$ROW_LIMIT \
        --output="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$IMPORTANCE_OUTPUT" \
        --type-source="$TYPE_SOURCE"
done

SUMMARY_MACHINE_OUTPUT=summary-machine.json
SUMMARY_REST_ENDPOINT=HTTP://10.108.4.42:5003
SUMMARY_FUNCTION=fileUpload

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Summarizing $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./distil-summary \
        --rest-endpoint="$SUMMARY_REST_ENDPOINT" \
        --summary-function="$SUMMARY_FUNCTION" \
        --dataset="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$MERGED_OUTPUT_HEADER_PATH" \
        --output="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$SUMMARY_MACHINE_OUTPUT"
done

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
