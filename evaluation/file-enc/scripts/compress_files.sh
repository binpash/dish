#!/bin/bash
# compress all files in a directory
mkdir -p $2

for item in $(hdfs dfs -ls -C $1);
do
    output_name=$(basename $item).zip
    hdfs dfs -cat -ignoreCrc $item | gzip -c > $2/$output_name
done

echo 'done';
