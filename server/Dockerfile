# Set the base image to elasticsearch alpine
FROM elasticsearch:5.4-alpine

ARG aws_access_key
ARG aws_secret_key
ARG aws_region
ARG smmry_key

ENV AWS_ACCESS_KEY=$aws_access_key
ENV AWS_SECRET_KEY=$aws_secret_key
ENV AWS_REGION=$aws_region
ENV SMMRY_API_KEY=$smmry_key

# make sure package db is up to date
RUN apk update

# missing from baseline alpine
RUN apk add --no-cache ca-certificates

# download build toolchain
RUN apk add --no-cache --virtual .build-deps \
  gcc \
  linux-headers \
  make \
  musl-dev \
  tar

# base ES image sets default data dir to volume which means it won't persist
# if we ingest.  We make a new directory for data here and update the config
# file to point to it.
RUN mkdir /data && \
  chown -R elasticsearch:elasticsearch /data && \
  echo 'path.data: /data' >> config/elasticsearch.yml && \
  echo 'http.compression: true' >> config/elasticsearch.yml

# copy in distil-ingest
RUN mkdir -p /distil-ingest
WORKDIR /distil-ingest
ADD config.sh .
ADD distil-ingest .
ADD distil-merge .
ADD distil-rank .
ADD distil-classify .
ADD ingest.sh .

# copy in d3m test data
RUN mkdir -p /input
ADD data /input

# start elasticsearch and run ingest
ADD https://raw.githubusercontent.com/vishnubob/wait-for-it/e1f115e4ca285c3c24e847c4dd4be955e0ed51c2/wait-for-it.sh /
RUN /docker-entrypoint.sh elasticsearch -p /tmp/epid & \
  /bin/bash /wait-for-it.sh -t 0 localhost:9200 -- /distil-ingest/ingest.sh; \
  kill $(cat /tmp/epid) && wait $(cat /tmp/epid); \
  exit 0;

# remove ingest related files
WORKDIR /
RUN rm -r -f /distil-ingest; \
  rm -r -f /distil-merge; \
  rm -r -f /distil-rank; \
  rm -r -f /distil-classify; \
  rm /wait-for-it.sh; \
  rm -r -f /input;

# copy run script across
ADD start_services.sh /

# expose standard ports
EXPOSE 9200
EXPOSE 9300

CMD . /start_services.sh
