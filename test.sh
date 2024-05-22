#!/bin/bash

# ./test.sh 1 --ft optimized --split 1 --pool 8 -d 1
# git pull; git submodule update; /opt/dish/runtime/scripts/killall.sh; sleep 2; pkill -f worker; sleep 2; /opt/dish/docker-hadoop/datanode/run.sh
# git pull; git submodule update; pkill -f worker; pkill -f discovery; pkill -f filereader; sleep 2; bash /opt/dish/pash/compiler/dspash/worker.sh &> /worker.log &

# Check if the first argument is a number
if ! [[ "$1" =~ ^[0-9]+$ ]]; then
    echo "The first argument must be a numeric value indicating the number of iterations."
    exit 1
fi

# Iterate from 1 to the number provided in the first argument
for (( i=1; i<=$1; i++ ))
do
    time (./di.sh sample.sh --parallel_pipelines --parallel_pipelines_limit 24 "${@:2}" 2> err.log)
    md5sum wwwc* | cut -d ' ' -f1 | sort | uniq -c | if read -r count hash && [ "$count" -eq 20 ]; then cat wwwc1.txt; else echo "Files are not identical"; fi
    echo "Iteration $i ended"
done
