#!/bin/bash

cd "$(realpath $(dirname "$0"))"

# if [[ if "$1" == "--all" ]]; then
#     hdfs dfs -rm -r /nlp
# fi
rm -rf ./inputs
rm -rf ./outputs
hdfs dfs -rm -r /nlp
