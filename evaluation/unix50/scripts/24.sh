#!/bin/bash

# 9.2: extract the word BELL
hdfs dfs -cat -ignoreCrc $1 | cut -c 1-1 | tr -d '\n'
