#!/bin/bash

# 9.3: animal that used to decorate the Unix room
hdfs dfs -cat -ignoreCrc $1 | cut -c 1-2 | tr -d '\n'
