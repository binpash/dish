#!/bin/bash

# 7.1: identify number of AT&T unix versions
hdfs dfs -cat -ignoreCrc $1 | cut -f 1 | grep 'AT&T' | wc -l
