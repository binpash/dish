#!/bin/bash
if [ "$1" == '--eval' ]; then
    export RELEASE="eval"
else
    export RELEASE="latest"
fi

## TODO: This should not build the images by default, but should just download them
make build

# https://docs.docker.com/compose/migrate
docker-compose up -d || docker compose up -d
