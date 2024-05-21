#!/bin/bash

# 11.1: year Ritchie and Thompson receive the Hamming medal
hdfs dfs -cat -ignoreCrc $1 | grep 'UNIX' | cut -f 1
