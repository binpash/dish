#!/bin/bash

# Create a new file
touch words-repeated.txt

# Write the contents of /usr/share/dict/words 100 times to the file
for i in {1..100}
do
    cat /usr/share/dict/words >> words-repeated.txt
done

# Put the file into HDFS
hdfs dfs -put words-repeated.txt /words-repeated.txt

# Remove the local file
rm words-repeated.txt
