#!/bin/bash

PASH_TOP=${PASH_TOP:-$(git rev-parse --show-toplevel)}

[[ "$1" == "-c" ]] && { rm -rf genesis exodus pg; exit; }

if [ ! -f ./genesis ]; then
    curl -sf https://www.gutenberg.org/cache/epub/8001/pg8001.txt > genesis
    "$PASH_TOP/scripts/append_nl_if_not.sh" genesis
fi 

if [ ! -f ./exodus ]; then
    curl -sf https://www.gutenberg.org/files/33420/33420-0.txt > exodus
    "$PASH_TOP/scripts/append_nl_if_not.sh" exodus
fi

if [ ! -e ./pg ]; then
    mkdir pg
    cd pg
    book_count=120
    if [[ "$1" == "--full" ]]; then
        book_count=1000
    fi

    head -n $book_count ../book_txt_links.txt | while IFS= read -r line
    do
        echo "Downloading $line"
        # Your code here
        wget -q "$line"
    done

    for f in *.txt; do
        "$PASH_TOP/scripts/append_nl_if_not.sh" $f
    done
    cd ..
fi

# Put files in hdfs
hdfs dfs -mkdir /nlp
hdfs dfs -put exodus /nlp/exodus
hdfs dfs -put genesis /nlp/genesis
hdfs dfs -put pg /nlp/pg
