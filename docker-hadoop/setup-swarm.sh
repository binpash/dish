#!/bin/bash
if [ $1 == '--eval' ]; then
    export RELEASE="eval"
else
    export RELEASE="latest"
fi


echo "Building the docker images"
make build

echo "Setting up the hbase network"
docker network create -d overlay --attachable hbase

echo "Setting up a local image registry"
docker service create --name registry --publish published=5000,target=5000  registry:2

# make build
for image in hadoop-historyserver hadoop-nodemanager hadoop-resourcemanager hadoop-datanode hadoop-namenode hadoop-pash-base; 
do 
    echo pushing $image 
    # docker rmi localhost:5000/$image:$RELEASE
    docker image tag  $image:$RELEASE localhost:5000/$image:$RELEASE; 
    docker image push  localhost:5000/$image:$RELEASE
    
done

echo "Deploying the swarm"
docker stack deploy -c docker-compose-v3.yml hadoop

./gen_config.sh
