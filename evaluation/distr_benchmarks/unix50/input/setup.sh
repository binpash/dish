#!/bin/bash

#set -e

PASH_TOP=${PASH_TOP:-$(realpath $(dirname setup.sh)/../../../../pash)}

## FIXME: These inputs are already 1G when downloaded
## FIXME: Also, wget is not silent like curl in the other setup scripts.

inputs=(
1 10 11 12 2 3 4 5 6 7 8 9.1 9.2 9.3 9.4 9.5 9.6 9.7 9.8 9.9
)

if [[ "$1" == "-c" ]]; then
    for input in ${inputs[@]}
    do
        rm -f "${input}.txt"
        rm -f "${input}_"*
        rm -rf "small"
        rm -rf "extended_input"
    done
    hdfs dfs -rm -r /unix50
    exit
fi

# Put files in hdfs
hdfs dfs -mkdir /unix50

# generate small inputs 
if [ "$#" -eq 1 ] && [ "$1" = "--small" ]; then
    echo "Generating small-size inputs"                                             
    mkdir small

    for input in ${inputs[@]}
    do
        if [ ! -f "small/${input}.txt" ]; then
            wget "http://atlas-group.cs.brown.edu/data/unix50/${input}.txt" -O "small/${input}.txt" -q
            "$PASH_TOP/scripts/append_nl_if_not.sh" "${input}.txt"
        fi
    done                                                                

    hdfs dfs -put small /unix50/small                                                                              
    return 0
fi

for input in ${inputs[@]}
do
    if [ ! -f "${input}.txt" ]; then
        wget "http://atlas-group.cs.brown.edu/data/unix50/${input}.txt" -q
        "$PASH_TOP/scripts/append_nl_if_not.sh" "${input}.txt"
    fi

    # Concatenate file with itself until it reaches 1GB
    while [ $(du -m "${input}.txt" | cut -f1) -lt 1024 ]; do
        cat "${input}.txt" "${input}.txt" >> "${input}_temp.txt"
        mv -f "${input}_temp.txt" "${input}.txt"
    done

    # If the file size exceeds 1GB, split it into 1GB chunks
    if [ $(du -m "${input}.txt" | cut -f1) -gt 1025 ]; then
        split -C 1024m --numeric-suffixes "${input}.txt" "${input}_"
        mv -f "${input}_00" "${input}.txt"
        rm "${input}_"*
    fi

    hdfs dfs -put "${input}.txt" /unix50/"${input}.txt"
    echo "Finished processing ${input}.txt"
done

# increase the original input size 10x
if [ "$#" -eq 1 ] && [ "$1" = "--extended" ]; then
    hdfs dfs -rm -r /unix50
    hdfs dfs -mkdir /unix50
    for file in *.txt; do
        for (( i = 0; i < 10; i++ )); do
            cat $file >> temp.txt
        done
        hdfs dfs -put temp.txt /unix50/$file
        rm temp.txt
        echo "Finished extending $file"
    done
fi


source_var() {
    if [[ "$1" == "--extended" ]]; then
        export IN_PRE=/unix50
    else
        export IN_PRE=/unix50
    fi
}
