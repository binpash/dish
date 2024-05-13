#!/bin/bash
# Calculate sort twice

hdfs dfs -cat -ignoreCrc $1 | tr A-Z a-z | sort | sort -r
