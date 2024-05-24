#!/bin/bash
# tag: four-letter words
# set -e

# the original script has both versions
IN=${IN:-/nlp/pg/}
OUT=${1:-$PASH_TOP/evaluation/nlp/outputs/6_2/}
ENTRIES=${ENTRIES:-1060}
mkdir -p "$OUT"

for input in $(hdfs dfs -ls -C ${IN} | head -n ${ENTRIES} | xargs -I arg1 basename arg1)
do
    hdfs dfs -cat -ignoreCrc $IN/$input | tr -c 'A-Za-z' '[\n*]' | grep -v "^\s*$" | grep -c '^....$' > ${OUT}/${input}.out0
    hdfs dfs -cat -ignoreCrc $IN/$input | tr -c 'A-Za-z' '[\n*]' | grep -v "^\s*$" | sort -u | grep -c '^....$'  > ${OUT}/${input}.out1
done

echo 'done';
# rm -rf "$OUT"
