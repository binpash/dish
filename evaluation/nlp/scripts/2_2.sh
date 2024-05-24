#!/bin/bash
# tag: count_vowel_seq
# set -e 

IN=${IN:-/nlp/pg/}
OUT=${1:-$PASH_TOP/evaluation/nlp/outputs/2_2/}
ENTRIES=${ENTRIES:-1000}
mkdir -p "$OUT"

for input in $(hdfs dfs -ls -C ${IN} | head -n ${ENTRIES} | xargs -I arg1 basename arg1)
do
    hdfs dfs -cat -ignoreCrc $IN/$input | tr 'a-z' '[A-Z]' | tr -sc 'AEIOU' '[\012*]'| sort | uniq -c  > ${OUT}/${input}.out
done

echo 'done';
# rm -rf "$OUT"
