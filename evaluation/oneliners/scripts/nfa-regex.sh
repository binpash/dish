#!/bin/bash
# Match complex regular-expression over input

hdfs dfs -cat -ignoreCrc $1 | tr A-Z a-z | grep '\(.\).*\1\(.\).*\2\(.\).*\3\(.\).*\4'
