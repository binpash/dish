#!/bin/bash

# 8.4: find longest words without hyphens
hdfs dfs -cat -ignoreCrc $1 | tr -c "[a-z][A-Z]" '\n' | sort | awk "length >= 16"
