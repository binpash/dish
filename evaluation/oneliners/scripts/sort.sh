#!/bin/bash
# Sort input

hdfs dfs -cat -ignoreCrc $1 | sort
