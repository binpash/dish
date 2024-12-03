#!/bin/bash

cd "$(realpath $(dirname "$0"))"
mkdir -p inputs
cd inputs

FROM=${FROM:-2015}
TO=${TO:-2015}
IN=${IN:-'http://atlas-group.cs.brown.edu/data/noaa/'}
fetch=${fetch:-"curl -sL"}

## Downloading and extracting
download_data() {
    seq $FROM $TO |
        sed "s;^;$IN;" |
        sed 's;$;/;' |
        xargs -r -n 1 $fetch |
        grep gz |
        tr -s ' \n' |
        cut -d ' ' -f9 |
        sed 's;^\(.*\)\(20[0-9][0-9]\).gz;\2/\1\2\.gz;' |
        sed "s;^;$IN;" |
        head -n $1 |
        xargs -n1 $fetch |
        gunzip > $2
}

download_data 1 temperatures_small.txt
download_data 14420 temperatures.txt

hdfs dfs -mkdir -p /max-temp

hdfs dfs -put temperatures_small.txt /max-temp/temperatures_small.txt
hdfs dfs -put temperatures.txt /max-temp/temperatures.txt
