#!/bin/bash
# tag: trigram_rec
# set -e

IN=${IN:-/nlp/pg/}
OUT=${1:-$PASH_TOP/evaluation/nlp/outputs/6_1/}
ENTRIES=${ENTRIES:-1060}
mkdir -p "$OUT"

pure_func() {
    input=$1
    TEMPDIR=$(mktemp -d)
    tr -sc '[A-Z][a-z]' '[\012*]' > ${TEMPDIR}/${input}.words
    tail +2 ${TEMPDIR}/${input}.words > ${TEMPDIR}/${input}.nextwords
    tail +3 ${TEMPDIR}/${input}.words > ${TEMPDIR}/${input}.nextwords2
    paste ${TEMPDIR}/${input}.words ${TEMPDIR}/${input}.nextwords ${TEMPDIR}/${input}.nextwords2 | sort | uniq -c
    rm -rf ${TEMPDIR}
}
export -f pure_func

for input in $(hdfs dfs -ls -C ${IN} | head -n ${ENTRIES} | xargs -I arg1 basename arg1)
do
    hdfs dfs -cat -ignoreCrc -ignoreCrc $IN/$input | grep 'the land of' | pure_func ${input} | sort -nr | sed 5q > ${OUT}/${input}.0.out
    hdfs dfs -cat -ignoreCrc -ignoreCrc $IN/$input | grep 'And he said' | pure_func ${input} | sort -nr | sed 5q > ${OUT}/${input}.1.out
done

echo 'done';
# rm -rf "$OUT"
