#!/bin/bash
./stop.sh

docker rm -vf $(docker ps --filter ancestor=pash-base -aq);
docker rmi -f $(docker images --format "{{.Repository}} {{.ID}}" | cut -d " " -f2)

echo "Warning: you will need to run image and volume on every swarm node"
docker image prune
docker system prune --volumes # you need to run this on every machine to clean up the disk