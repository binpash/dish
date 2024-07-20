#!/bin/bash

cd "$(realpath $(dirname "$0"))"
rm -rf ./inputs
rm -rf ./outputs
hdfs dfs -rm -r /media-conv
