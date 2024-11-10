#!/bin/bash 
# tag: bigrams.sh
# set -e

# Bigrams (contrary to our version, this uses intermediary files)
IN=${IN:-/nlp/pg/}
OUT=${OUT:-$PASH_TOP/evaluation/distr_benchmarks/nlp/output/4_3/}
ENTRIES=${ENTRIES:-1060}
mkdir -p "$OUT"

pure_func() {
    input=$1
    TEMPDIR=$(mktemp -d)

    # Ensure TEMPDIR is deleted on function exit, even if an error occurs
    trap 'rm -rf ${TEMPDIR}' EXIT

    cat > ${TEMPDIR}/${input}.input.words
    tail +2 ${TEMPDIR}/${input}.input.words > ${TEMPDIR}/${input}.input.nextwords
    paste ${TEMPDIR}/${input}.input.words ${TEMPDIR}/${input}.input.nextwords
}
export -f pure_func

for input in $(hdfs dfs -ls -C ${IN} | head -n ${ENTRIES} | xargs -n 1 -I arg1 basename arg1)
do
    hdfs dfs -cat -ignoreCrc $IN/$input |  tr -c 'A-Za-z' '[\n*]' | grep -v "^\s*$"| pure_func $input| sort | uniq -c > ${OUT}/${input}.input.bigrams
done

echo 'done';
rm -rf ${OUT}
