#!/bin/bash

# #Check that we are in the appropriate directory where setup.sh is
# #https://stackoverflow.com/a/246128
# DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# echo "changing to $DIR to run setup.sh"
# cd $DIR

PASH_TOP=${PASH_TOP:-$(git rev-parse --show-toplevel)}
mkdir -p inputs
cd inputs

hdfs dfs -mkdir /covid-mts
if [ ! -f ./in.csv ] && [ "$1" != "--small" ]; then
  curl -f 'https://atlas-group.cs.brown.edu/data/covid-mts/in.csv.gz'> in.csv.gz
  gzip -d in.csv.gz
  hdfs dfs -put in.csv  /covid-mts/in.csv
elif [ ! -f ./in_small.csv ] && [ "$1" = "--small" ]; then
  if [ ! -f ./in_small.csv ]; then                                                       
    echo "Generating small-size inputs"                                                  
    curl -f 'https://atlas-group.cs.brown.edu/data/covid-mts/in_small.csv.gz' > in_small.csv.gz
    gzip -d in_small.csv.gz
  fi
  hdfs dfs -put in_small.csv  /covid-mts/in_small.csv                                                                                     
fi
