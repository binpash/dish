#!/bin/bash

# 1.2: extract names and sort
hdfs dfs -cat -ignoreCrc $1 | head -n 2 | cut -d ' ' -f 2
