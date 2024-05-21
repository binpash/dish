#!/bin/bash

# 8.1: count unix birth-year
hdfs dfs -cat -ignoreCrc $1 | tr ' ' '\n' | grep 1969 | wc -l
