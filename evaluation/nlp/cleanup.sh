#!/bin/bash

cd "$(realpath $(dirname "$0"))"

# if [[ if "$1" == "--all" ]]; then
#     rm -rf genesis exodus pg;
#     hdfs dfs -rm -r /
# fi
rm -rf ./inputs
rm -rf ./outputs
rm -rf genesis exodus pg;
hdfs dfs -rm -r /
