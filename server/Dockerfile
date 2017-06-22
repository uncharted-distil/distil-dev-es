# Set the base image to elasticsearch alpine
FROM elasticsearch:5.4-alpine

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

# download and extract redis src
RUN wget -O redis.tar.gz http://download.redis.io/releases/redis-3.2.8.tar.gz; \
  mkdir -p /usr/src/redis; \
  tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1; \
  rm redis.tar.gz

# build redis and clean up
RUN make -C /usr/src/redis && make -C /usr/src/redis install; \
  rm -r /usr/src/redis && apk del .build-deps; \
  mkdir -p /usr/local/var/db/redis
ADD redis.conf /etc


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
  rm /wait-for-it.sh; \
  rm -r -f /input;

# copy run script across
ADD start_services.sh /

# expose standard ports
EXPOSE 6379
EXPOSE 9200
EXPOSE 9300

CMD . /start_services.sh
