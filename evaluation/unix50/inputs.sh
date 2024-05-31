#!/bin/bash

cd "$(realpath $(dirname "$0"))"
mkdir -p inputs
cd inputs

inputs=(1 10 11 12 2 3 4 5 6 7 8 9.1 9.2 9.3 9.4 9.5 9.6 9.7 9.8 9.9)

for input in ${inputs[@]}
do
    if [ ! -f "${input}.txt" ]; then
        wget "http://atlas-group.cs.brown.edu/data/unix50/${input}.txt" -q
    fi

    if [ ! -f "${input}_1M.txt" ]; then
        file_content_size=$(wc -c < "${input}.txt")
        iteration_limit=$((1048576 / $file_content_size))
        for (( i = 0; i < iteration_limit; i++ )); do
            cat "${input}.txt" >> "${input}_1M.txt"
        done
    fi

    if [ ! -f "${input}.txt" ]; then
        for (( i = 0; i < 3000; i++ )); do
            cat "${input}_1M.txt" >> "${input}.txt"
        done
    fi

    echo "Finished processing ${input}.txt"
done


hdfs dfs -mkdir -p /unix50
for file in "${inputs[@]}"; do
    hdfs dfs -put "${file}_1M.txt" "/unix50/${file}_1M.txt"
    hdfs dfs -put "${file}.txt" "/unix50/${file}.txt"
    echo "Put $file to hdfs"
done
