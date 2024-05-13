#!/bin/bash

cd "$(dirname "$0")"
rm -rf ./inputs
rm -rf ./outputs
hdfs dfs -rm -rf /oneliners
