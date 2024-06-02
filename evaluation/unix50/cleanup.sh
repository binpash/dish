#!/bin/bash

cd "$(realpath $(dirname "$0"))"
rm -rf ./inputs
rm -rf ./outputs
hdfs dfs -rm -r /unix50
hdfs dfs -rm -r /outputs/hadoop-streaming/unix50
