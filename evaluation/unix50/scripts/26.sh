#!/bin/bash

# 9.4: four corners with E centered, for an "X" configuration
hdfs dfs -cat -ignoreCrc $1 | tr ' ' '\n' | grep "\"" | sed 4d | cut -d "\"" -f 2 | tr -d '\n'
