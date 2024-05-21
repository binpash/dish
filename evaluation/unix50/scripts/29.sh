#!/bin/bash

# 9.7: Four corners
hdfs dfs -cat -ignoreCrc $1 | sed 2d | sed 2d | tr -c '[A-Z]' '\n' | tr -d '\n'
