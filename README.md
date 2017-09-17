# distil-dev-es

Provides a dockerfile and supporting scripts to generate images containing Elasticsearch v5.4. The image build step uses [distil-ingest](https://github.com/unchartedsoftware/distil-ingest) to build a [distil](https://github.com/unchartedsoftware/distil)-ready index from source data; this index is saved as part of the image, allowing for generation of drop-in test container that can be run locally.

## Dependencies

- [Go](https://golang.org/) version 1.6+ with the `GOPATH` environment variable specified and `$GOPATH/bin` in your `PATH`.
- [Docker](http://www.docker.com/) platform.

## Building the Image

1. Edit `./server/config.sh`:
    - Ensure the docker image name and version are specified:
        - `DOCKER_IMAGE_NAME`
        - `DOCKER_IMAGE_VERSION`
    - Ensure the data path, and datasets are specified and data stored under those paths:
        - `DATASETS`
        - `HOST_DATA_DIR`
2. Run `./build.sh` to build the image.

## Deploying the Container

A container based on the image can be deployed using the provided `./run.sh` script, or a command based on the contents of that script.  *Note*: The `--user elasticsearch` parameter must be passed to `docker run` or the command will fail..
