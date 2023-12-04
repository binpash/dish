#!/bin/bash
if [ $1 == '--eval' ]; then
    export RELEASE="eval"
else
    export RELEASE="latest"
fi

echo "Generating config"
./gen_config.sh

docker-compose -f docker-compose-client.yml up -d