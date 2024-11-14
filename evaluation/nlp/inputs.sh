#!/bin/bash

cd "$(realpath $(dirname "$0"))"
mkdir -p inputs
cd inputs

if [ ! -f ./book_links.txt ]; then
    wget -q -O book_links.txt "https://atlas-group.cs.brown.edu/data/gutenberg/books.txt"
    if [ ! -f book_links.txt ]; then
        echo "Failed to download book_links.txt"
        exit 1
    fi
fi

if [ ! -f ./genesis ]; then
    curl -sf https://atlas-group.cs.brown.edu/data/gutenberg/8/0/0/8001/8001.txt > genesis
    # Add newline to the original file
    echo >> genesis
fi 

if [ ! -f ./exodus ]; then
    curl -sf https://atlas-group.cs.brown.edu/data/gutenberg/3/3/4/2/33420/33420-0.txt > exodus
    # Add newline to the original file
    echo >> exodus 
fi

if [ ! -e ./pg ]; then
    mkdir pg
    cd pg
    book_count=100
    echo "Downloading $book_count books"

    head -n $book_count ../book_links.txt | while IFS= read -r line
    do
        full_url="https://atlas-group.cs.brown.edu/data/gutenberg/${line}"
        # echo "Downloading $full_url"
        wget -q "$full_url"
    done
    # Add newline to the original file
    for f in *.txt; do
        echo >> $f
    done

    echo "Downloaded $book_count books"
    cd ..
fi

if [ ! -e ./pg-small ]; then
    mkdir pg-small
    cd pg-small
    book_count=10
    echo "Downloading $book_count books"

    head -n $book_count ../book_links.txt | while IFS= read -r line
    do
        full_url="https://atlas-group.cs.brown.edu/data/gutenberg/${line}"
        # echo "Downloading $full_url"
        wget -q "$full_url"
    done
    # Add newline to the original file
    for f in *.txt; do
        echo >> $f
    done

    echo "Downloaded $book_count books"
    cd ..
fi

# Put files in hdfs
hdfs dfs -mkdir /nlp
hdfs dfs -put exodus /nlp/exodus
hdfs dfs -put genesis /nlp/genesis
hdfs dfs -put pg /nlp/pg
hdfs dfs -put pg-small /nlp/pg-small
