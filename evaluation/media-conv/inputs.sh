#!/bin/bash

cd "$(realpath $(dirname "$0"))"
mkdir -p inputs
cd inputs

hdfs dfs -mkdir /media-conv

if [ ! -d ${IN}/wav ]; then
    WAV_DATA_FILES=120
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
if [ ! -d ${IN}/wav_small ]; then
    WAV_DATA_FILES=20
    wget -O wav_small.zip https://atlas-group.cs.brown.edu/data/wav.zip
    unzip wav_small.zip && cd wav_small/
    for f in *.wav; do
        FILE=$(basename "$f")
        for (( i = 0; i <= $WAV_DATA_FILES; i++)) do
            echo copying to $f$i.wav
            cp $f $f$i.wav
        done
    done
    cd ..
    hdfs dfs -put wav_small /media-conv/wav_small
    echo "WAV_small Generated"
fi

if [ ! -d ${IN}/jpg ]; then
    JPG_DATA_LINK=https://atlas-group.cs.brown.edu/data/full/jpg.zip
    wget $JPG_DATA_LINK
    unzip jpg.zip
    hdfs dfs -put jpg /media-conv/jpg
    echo "JPG Generated"
    rm -rf ${IN}/jpg.zip
fi
if [ ! -d ${IN}/jpg_small ]; then
    JPG_DATA_LINK=https://atlas-group.cs.brown.edu/data/small/jpg.zip
    wget -O jpg_small.zip $JPG_DATA_LINK
    unzip jpg_small.zip
    hdfs dfs -put jpg_small /media-conv/jpg_small
    echo "JPG_small Generated"
    rm -rf ${IN}/jpg_small.zip
fi
