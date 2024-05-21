#!/bin/bash

# 5.1: extract hello world
hdfs dfs -cat -ignoreCrc $1 | grep 'print' | cut -d "\"" -f 2 | cut -c 1-12
