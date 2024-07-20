#!/bin/bash

cd "$(realpath $(dirname "$0"))"
mkdir -p inputs
cd inputs

hdfs dfs -mkdir /media-conv

IN=${inputs}

if [ ! -d ${IN}/wav ]; then
    wget https://atlas-group.cs.brown.edu/data/wav.zip
    unzip wav.zip && cd wav/
    for f in *.wav; do
        FILE=$(basename "$f")
        for (( i = 0; i <= $WAV_DATA_FILES; i++)) do
            echo copying to $f$i.wav
            cp $f $f$i.wav
        done
    done
    cd ..
    hdfs dfs -put wav /media-conv/wav
    echo "WAV Generated"
fi

if [ ! -d ${IN}/jpg ]; then
    cd ${IN}
    wget https://atlas-group.cs.brown.edu/data/full/jpg.zip
    unzip jpg.zip
    hdfs dfs -put jpg /media-conv/jpg
    echo "JPG Generated"
    rm -rf ${IN}/jpg.zip
fi
