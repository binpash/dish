#!/bin/bash

# 1.3: sort top first names
hdfs dfs -cat -ignoreCrc $1 | cut -d ' ' -f 1 | sort | uniq -c | sort -r
