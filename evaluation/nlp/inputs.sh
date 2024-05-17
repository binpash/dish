#!/bin/bash

PASH_TOP=${PASH_TOP:-$(git rev-parse --show-toplevel)}
cd "$(realpath $(dirname "$0"))"
mkdir -p inputs
cd inputs

BOOKS_URL="https://atlas-group.cs.brown.edu/data/gutenberg/books.txt"
BASE_URL="https://atlas-group.cs.brown.edu/data/gutenberg/"

if [ ! -f ./book_links.txt ]; then
    wget -q -O book_links.txt "$BOOKS_URL"
    if [ ! -f book_links.txt ]; then
        echo "Failed to download book_links.txt"
        exit 1
    fi
fi

if [ ! -f ./genesis ]; then
    # original link: https://www.gutenberg.org/cache/epub/8001/pg8001.txt
    curl -sf https://atlas-group.cs.brown.edu/data/gutenberg/8/0/0/8001/8001.txt > genesis
    "$PASH_TOP/scripts/append_nl_if_not.sh" genesis
fi 

if [ ! -f ./exodus ]; then
    # original link: https://www.gutenberg.org/files/33420/33420-0.txt
    curl -sf https://atlas-group.cs.brown.edu/data/gutenberg/3/3/4/2/33420/33420-0.txt > exodus
    "$PASH_TOP/scripts/append_nl_if_not.sh" exodus
fi

if [ ! -e ./pg ]; then
    mkdir pg
    cd pg
    book_count=120
    if [[ "$1" == "--small" ]]; then
        book_count=10
    fi

    if [[ "$1" == "--full" ]]; then
        book_count=1000
    fi

    head -n $book_count ../book_links.txt | while IFS= read -r line
    do
        full_url="${BASE_URL}${line}"
        echo "Downloading $full_url"
        wget -q "$full_url"
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
