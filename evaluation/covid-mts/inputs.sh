#!/bin/bash

cd "$(realpath $(dirname "$0"))"
mkdir -p inputs
cd inputs

if [ ! -f ./in.csv ]; then
    curl -s -f 'https://atlas-group.cs.brown.edu/data/covid-mts/in.csv.gz' > in.csv.gz
    gzip -d in.csv.gz
    # Add newline to the original file
    echo >> in.csv

    # repeat in.csv 10 times
    for i in {1..10}; do
        cat in.csv >> in.csv.tmp
    done

    rm in.csv
    mv in.csv.tmp in.csv
fi

if [ ! -f ./in_small.csv ]; then
    curl -s -f 'https://atlas-group.cs.brown.edu/data/covid-mts/in_small.csv.gz' > in_small.csv.gz
    gzip -d in_small.csv.gz
    # Add newline to the original file
    echo >> in_small.csv
fi

hdfs dfs -mkdir -p /covid-mts
hdfs dfs -put in.csv /covid-mts/in.csv
hdfs dfs -put in_small.csv /covid-mts/in_small.csv
rm in.csv in_small.csv
