#!/bin/bash

cd "$(realpath $(dirname "$0"))"
mkdir -p inputs
cd inputs

input_files=("1M.txt" "3G.txt" "all_cmds.txt" "all_cmds_3G.txt" "dict.txt")

if [ ! -f ./1M.txt ]; then
    wget https://atlas-group.cs.brown.edu/data/dummy/1M.txt
    # TODO: Add newline to the original file
    echo >> 1M.txt
fi

if [ ! -f ./3G.txt ]; then
    touch 3G.txt
    for (( i = 0; i < 3000; i++ )); do
        cat 1M.txt >> 3G.txt
    done
fi

if [ ! -f ./dict.txt ]; then
    wget -O - https://atlas-group.cs.brown.edu/data/dummy/dict.txt | sort > dict.txt
fi

if [ ! -f ./all_cmds.txt ]; then
    # TODO: Upload this file to the server
    # cp ../all_cmds.txt all_cmds.txt
    ls /usr/bin/* > all_cmds.txt
fi

if [ ! -f ./all_cmds_3G.txt ]; then
    touch all_cmds_3G.txt
    size_of_all_cmds=$(du -b all_cmds.txt | cut -f1)
    iterations=$((3000*1024*1024 / size_of_all_cmds))

    for ((i=0; i<$iterations; i++)); do
        cat all_cmds.txt >> all_cmds_3G.txt
    done
fi

hdfs dfs -mkdir -p /oneliners

for file in "${input_files[@]}"; do
    hdfs dfs -put $file /oneliners/$file
done

# Clean up inputs
cd ..
rm -rf inputs
