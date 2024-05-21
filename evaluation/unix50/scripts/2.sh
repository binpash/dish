#!/bin/bash

# 1.1: extract names and sort
hdfs dfs -cat -ignoreCrc $1 | cut -d ' ' -f 2 | sort
