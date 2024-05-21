#!/bin/bash

# 4.2: find pieces captured by Belle
hdfs dfs -cat -ignoreCrc $1 | tr ' ' '\n' | grep 'x' | grep '\.' | wc -l
