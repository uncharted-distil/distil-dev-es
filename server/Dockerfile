# Set the base image to elasticsearch alpine
FROM docker-hub.uncharted.software/elasticsearch:7.7.0

# build tools
RUN yum -y install wget
RUN yum -y groupinstall "Development tools"

# build gdal
RUN mkdir /build
WORKDIR /build
RUN wget http://download.osgeo.org/gdal/2.4.2/gdal-2.4.2.tar.gz
RUN tar xvzf gdal-2.4.2.tar.gz
WORKDIR gdal-2.4.2

# Prefix is pointing to my empty directory to not mix with my other GDAL install
RUN ./configure
RUN make
RUN make install
ENV PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/local/lib/pkgconfig
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

# setup go
WORKDIR /build
RUN wget https://dl.google.com/go/go1.13.12.linux-amd64.tar.gz
RUN tar -zxvf go1.13.12.linux-amd64.tar.gz -C /usr/local
RUN mkdir /go_home
ENV GOROOT=/usr/local/go
ENV GOPATH=/go_home
ENV PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# get go to build ingest
ARG DISTIL_BRANCH
ENV GOPROXY=direct
ENV GO111MODULE=on

# copy in distil-ingest
RUN yum -y install http://opensource.wandisco.com/centos/7/git/x86_64/wandisco-git-release-7-2.noarch.rpm
RUN yum -y install git
RUN mkdir -p /build/distil-ingest
WORKDIR /build/distil-ingest
ADD config.sh .
ADD ingest.sh .
RUN env GOOS=linux GOARCH=amd64 go get -a -v github.com/uncharted-distil/distil-ingest/cmd/distil-ingest@$DISTIL_BRANCH
RUN cp $GOPATH/bin/distil-ingest .

# base ES image sets default data dir to volume which means it won't persist
# if we ingest.  We make a new directory for data here and update the config
# file to point to it.
WORKDIR /usr/share/elasticsearch
RUN mkdir /data && \
    chown -R elasticsearch:elasticsearch /data && \
    echo 'path.data: /data' >> config/elasticsearch.yml && \
    echo 'http.compression: true' >> config/elasticsearch.yml
# also flag ES to run in single instance mode (for dev/test configs)
ENV xpack.security.enabled=false
ENV discovery.type=single-node

# copy in d3m test data
RUN mkdir -p /input
COPY data /input

# copy in support scripts
ADD https://raw.githubusercontent.com/vishnubob/wait-for-it/e1f115e4ca285c3c24e847c4dd4be955e0ed51c2/wait-for-it.sh /build
RUN chmod 777 /build/wait-for-it.sh
ADD start_services.sh /

ARG CACHEBUSTER=0
# start up ES and ingest data into it
USER elasticsearch
RUN elasticsearch & \
    /bin/bash /build/wait-for-it.sh -t 90 localhost:9200 -- /build/distil-ingest/ingest.sh; \
    exit 0;

# clean up all the build cruft
USER root
RUN rm -rf /build
RUN rm -rf /input
RUN rm -rf /go_home
RUN rm -rf /usr/local/go
RUN rm -rf /usr/local/lib
RUN mkdir /usr/local/lib

#expose standard ports
EXPOSE 9200
EXPOSE 9300

# make sure we run ES as the elasticsearch user (running as root is not allowed)
USER elasticsearch
CMD . /start_services.sh
