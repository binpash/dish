#!/bin/bash

# 1.0: extract the last name
hdfs dfs -cat -ignoreCrc $1 | cut -d ' ' -f 2
