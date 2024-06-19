#!/bin/bash

cd "$(realpath $(dirname "$0"))"

git pull
git submodule update

/opt/dish/runtime/scripts/build.sh

if [[ "$@" == *"--main"* ]]; then
    pkill -f worker
    pkill -f discovery
    pkill -f filereader
    sleep 2
    bash /opt/dish/pash/compiler/dspash/worker.sh &> /worker.log &
else
    /opt/dish/runtime/scripts/killall.sh
    sleep 2
    pkill -f worker
    sleep 2
    /opt/dish/docker-hadoop/datanode/run.sh
fi
