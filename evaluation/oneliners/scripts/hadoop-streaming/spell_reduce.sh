#!/bin/bash
dict=/oneliners/dict.txt
# Sed to remove trailing tabs from each line
sed 's/[[:space:]]*$//' | uniq | comm -23 - <(hdfs dfs -cat $dict)
