#!/bin/bash

source ./server/config.sh

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

rm -rf $HOST_DATA_DIR_COPY
mkdir -p $HOST_DATA_DIR_COPY
for DATASET in "${DATASETS_SEED[@]}"
do
    echo "cp $HOST_DATA_DIR/$DATASET into $HOST_DATA_DIR_COPY/$DATASET"
    cp -r $HOST_DATA_DIR/$DATASET $HOST_DATA_DIR_COPY
done

for DATASET in "${DATASETS_EVAL[@]}"
do
    echo "cp $HOST_DATA_DIR_EVAL/$DATASET into $HOST_DATA_DIR_COPY/$DATASET"
    cp -r $HOST_DATA_DIR_EVAL/$DATASET $HOST_DATA_DIR_COPY
done

SCHEMA=/datasetDoc.json
CLUSTER_OUTPUT_DATA=clusters/tables/learningData.csv
CLUSTER_OUTPUT_SCHEMA=clusters/datasetDoc.json
HAS_HEADER=1
PRIMITIVE_ENDPOINT=localhost:50051
DATA_LOCATION=/input/d3m

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Clustering $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./server/distil-cluster \
        --endpoint="$PRIMITIVE_ENDPOINT" \
        --dataset="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN" \
        --media-path="$DATA_LOCATION/${DATASET}/TRAIN/dataset_TRAIN/" \
        --schema="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/$SCHEMA" \
        --output="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/$CLUSTER_OUTPUT_DATA" \
        --output-schema="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/$CLUSTER_OUTPUT_SCHEMA" \
        --has-header=$HAS_HEADER
done

FEATURE_OUTPUT_DATA=features/tables/learningData.csv
FEATURE_OUTPUT_SCHEMA=features/datasetDoc.json

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Featurizing $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./server/distil-featurize \
        --endpoint="$PRIMITIVE_ENDPOINT" \
        --dataset="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN" \
        --media-path="$DATA_LOCATION/${DATASET}/TRAIN/dataset_TRAIN/" \
        --schema="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/$CLUSTER_OUTPUT_SCHEMA" \
        --output="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/$FEATURE_OUTPUT_DATA" \
        --output-schema="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/$FEATURE_OUTPUT_SCHEMA" \
        --has-header=$HAS_HEADER
done

MERGED_DATASET_FOLDER=merged
MERGED_OUTPUT_PATH=merged/tables/mergedNoHeader.csv
MERGED_OUTPUT_PATH_RELATIVE=tables/learningData.csv
MERGED_OUTPUT_HEADER_PATH=merged/tables/learningData.csv
MERGED_OUTPUT_SCHEMA=merged/datasetDoc.json
MERGE_HAS_HEADER=1

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Merging $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./server/distil-merge \
        --schema="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/$FEATURE_OUTPUT_SCHEMA" \
        --data="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/$FEATURE_OUTPUT_DATA" \
        --raw-data="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/" \
        --output-path="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/$MERGED_OUTPUT_PATH" \
        --output-path-relative="$MERGED_OUTPUT_PATH_RELATIVE" \
        --output-path-header="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/$MERGED_OUTPUT_HEADER_PATH" \
        --output-schema-path="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/$MERGED_OUTPUT_SCHEMA" \
        --has-header=$MERGE_HAS_HEADER
done

CLASSIFICATION_OUTPUT_PATH=classification.json

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Classifying $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./server/distil-classify \
        --endpoint="$PRIMITIVE_ENDPOINT" \
        --dataset="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/$MERGED_DATASET_FOLDER" \
        --output="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/$CLASSIFICATION_OUTPUT_PATH"
done

IMPORTANCE_OUTPUT=importance.json

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Ranking $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./server/distil-rank \
        --dataset="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/$MERGED_DATASET_FOLDER" \
        --endpoint="$PRIMITIVE_ENDPOINT" \
        --output="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/$IMPORTANCE_OUTPUT"
done

SUMMARY_MACHINE_OUTPUT=summary-machine.json

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Summarizing $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./server/distil-summary \
        --endpoint="$PRIMITIVE_ENDPOINT" \
        --dataset="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/$MERGED_DATASET_FOLDER" \
        --output="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/$SUMMARY_MACHINE_OUTPUT"
done
