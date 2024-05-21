#!/bin/bash

# 4.1: find number of rounds
hdfs dfs -cat -ignoreCrc $1 | tr ' ' '\n' | grep '\.' | wc -l
