#!/bin/bash

cd "$(realpath $(dirname "$0"))"
mkdir -p inputs
cd inputs

input_files=("1M.txt" "1G.txt" "3G.txt" "all_cmds.txt" "all_cmdsx1000.txt" "dict.txt")

if [ ! -f ./1M.txt ]; then
    wget -q https://atlas-group.cs.brown.edu/data/dummy/1M.txt
    # TODO: Add newline to the original file
    echo >> 1M.txt
fi

if [ ! -f ./1G.txt ]; then
    touch 1G.txt
    for (( i = 0; i < 1000; i++ )); do
        cat 1M.txt >> 1G.txt
    done
fi

if [ ! -f ./3G.txt ]; then
    touch 3G.txt
    for (( i = 0; i < 3; i++ )); do
        cat 1G.txt >> 3G.txt
    done
fi

if [ ! -f ./dict.txt ]; then
    wget -q -O - https://atlas-group.cs.brown.edu/data/dummy/dict.txt | sort > dict.txt
fi

if [ ! -f ./all_cmds.txt ]; then
    # TODO: Upload this file to the server
    # cp ../all_cmds.txt all_cmds.txt
    ls /usr/bin/* > all_cmds.txt
fi

if [ ! -f ./all_cmdsx1000.txt ]; then
    touch all_cmdsx1000.txt
    for (( i = 0; i < 1000; i++ )); do
        cat all_cmds.txt >> all_cmdsx1000.txt
    done
fi

hdfs dfs -mkdir -p /oneliners

for file in "${input_files[@]}"; do
    hdfs dfs -put $file /oneliners/$file
done

# Delete everything inisde inputs except dict.txt
find . -type f ! -name 'dict.txt' -delete
