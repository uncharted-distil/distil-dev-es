#!/bin/bash

source ./server/config.sh

env GOOS=linux GOARCH=amd64 go get -a -v github.com/uncharted-distil/distil-ingest/cmd/distil-merge@$BRANCH
env GOOS=linux GOARCH=amd64 go get -a -v github.com/uncharted-distil/distil-ingest/cmd/distil-classify@$BRANCH
env GOOS=linux GOARCH=amd64 go get -a -v github.com/uncharted-distil/distil-ingest/cmd/distil-rank@$BRANCH
env GOOS=linux GOARCH=amd64 go get -a -v github.com/uncharted-distil/distil-ingest/cmd/distil-ingest@$BRANCH
env GOOS=linux GOARCH=amd64 go get -a -v github.com/uncharted-distil/distil-ingest/cmd/distil-summary@$BRANCH
env GOOS=linux GOARCH=amd64 go get -a -v github.com/uncharted-distil/distil-ingest/cmd/distil-cluster@$BRANCH
env GOOS=linux GOARCH=amd64 go get -a -v github.com/uncharted-distil/distil-ingest/cmd/distil-geocode@$BRANCH
env GOOS=linux GOARCH=amd64 go get -a -v github.com/uncharted-distil/distil-ingest/cmd/distil-format@$BRANCH
env GOOS=linux GOARCH=amd64 go get -a -v github.com/uncharted-distil/distil-ingest/cmd/distil-clean@$BRANCH
mv $GOPATH/bin/distil-merge ./server
mv $GOPATH/bin/distil-classify ./server
mv $GOPATH/bin/distil-rank ./server
mv $GOPATH/bin/distil-ingest ./server
mv $GOPATH/bin/distil-summary ./server
mv $GOPATH/bin/distil-cluster ./server
mv $GOPATH/bin/distil-geocode ./server
mv $GOPATH/bin/distil-format ./server
mv $GOPATH/bin/distil-clean ./server

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

for DATASET in "${DATASETS_DA[@]}"
do
    echo "cp $HOST_DATA_DIR_DA/$DATASET into $HOST_DATA_DIR_COPY/$DATASET"
    cp -r $HOST_DATA_DIR_DA/$DATASET $HOST_DATA_DIR_COPY
done

rm -rf $OUTPUT_DATA_DIR
mkdir -p $OUTPUT_DATA_DIR
#docker run \
#    --name distil-auto-ml \
#    --rm \
#    -d \
#    -p 45042:45042 \
#    --env D3MOUTPUTDIR=$OUTPUT_DATA_DIR \
#    --env D3MINPUTDIR=$HOST_DATA_DIR_COPY \
#    --env D3MSTATICDIR=$D3MSTATICDIR \
#    --env PROGRESS_INTERVAL=60 \
#    -v $HOST_DATA_DIR_COPY:$HOST_DATA_DIR_COPY \
#    -v $OUTPUT_DATA_DIR:$OUTPUT_DATA_DIR \
#    -v $D3MSTATICDIR:$D3MSTATICDIR \
#    registry.datadrivendiscovery.org/uncharted/distil-integration/distil-auto-ml:latest
echo "Waiting for the pipeline runner to be available..."
sleep 200

SCHEMA=/datasetDoc.json
HAS_HEADER=1
PRIMITIVE_ENDPOINT=localhost:45042
CLUSTER_OUTPUT_FOLDER=clusters

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Clustering $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./server/distil-cluster \
        --endpoint="$PRIMITIVE_ENDPOINT" \
        --dataset="${DATASET}" \
        --input="$HOST_DATA_DIR_COPY" \
        --schema="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/$SCHEMA" \
        --output="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$CLUSTER_OUTPUT_FOLDER"
done

MERGED_DATASET_FOLDER=merged

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Merging $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./server/distil-merge \
        --endpoint="$PRIMITIVE_ENDPOINT" \
        --dataset="${DATASET}" \
        --input="$HOST_DATA_DIR_COPY" \
        --schema="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/$SCHEMA" \
        --output="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$MERGED_DATASET_FOLDER"
done

FORMAT_OUTPUT_FOLDER=format

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " FORMATTING $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./server/distil-format \
        --endpoint="$PRIMITIVE_ENDPOINT" \
        --dataset="${DATASET}" \
        --input="$HOST_DATA_DIR_COPY" \
        --schema="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/$SCHEMA" \
        --output="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$FORMAT_OUTPUT_FOLDER"
done

CLEANING_DATASET_FOLDER=clean

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Cleaning $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./server/distil-clean \
        --endpoint="$PRIMITIVE_ENDPOINT" \
        --dataset="${DATASET}" \
        --input="$HOST_DATA_DIR_COPY" \
        --schema="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/$SCHEMA" \
        --output="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$CLEANING_DATASET_FOLDER"
done

CLASSIFICATION_OUTPUT_PATH=classification.json

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Classifying $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./server/distil-classify \
        --endpoint="$PRIMITIVE_ENDPOINT" \
        --input="$HOST_DATA_DIR_COPY" \
        --schema="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/$SCHEMA" \
        --dataset="${DATASET}" \
        --output="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$CLASSIFICATION_OUTPUT_PATH"
done

IMPORTANCE_OUTPUT=importance.json

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Ranking $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./server/distil-rank \
        --endpoint="$PRIMITIVE_ENDPOINT" \
        --input="$HOST_DATA_DIR_COPY" \
        --schema="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/$SCHEMA" \
        --dataset="${DATASET}" \
        --output="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$IMPORTANCE_OUTPUT"
done

SUMMARY_MACHINE_OUTPUT=summary-machine.json

# Duke fails on large dataset (geolife)
for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Summarizing $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    if [ "$DATASET" == "LL1_336_MS_Geolife_transport_mode_prediction_separate_lat_lon" ];
    then
        echo "SKIPPING SUMMARY"
    else
        ./server/distil-summary \
            --endpoint="$PRIMITIVE_ENDPOINT" \
            --input="$HOST_DATA_DIR_COPY" \
            --schema="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/$SCHEMA" \
            --dataset="${DATASET}" \
            --output="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$SUMMARY_MACHINE_OUTPUT"
    fi
done

GEO_OUTPUT_FOLDER=geocoded
GEO_OUTPUT_DATA=geocoded/tables/learningData.csv
GEO_OUTPUT_SCHEMA=geocoded/datasetDoc.json

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Geocoding $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
#    ./server/distil-geocode \
#        --endpoint="$PRIMITIVE_ENDPOINT" \
#        --input="$HOST_DATA_DIR_COPY" \
#        --dataset="${DATASET}" \
#        --schema="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/$SCHEMA" \
#        --output="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$GEO_OUTPUT_FOLDER"
    # copy the data to the right path for ingest, and also copy it so that the dataset folder gets set properly on ingest
    mkdir -p "$OUTPUT_DATA_DIR/${DATASET}/TRAIN"
    cp -r "$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN" "$OUTPUT_DATA_DIR/${DATASET}/TRAIN/"
    cp -r "$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN" "$OUTPUT_DATA_DIR/${DATASET}/"
done
