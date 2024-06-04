#!/bin/bash

## Processing
hdfs dfs -cat -ignoreCrc $1 |
  cut -c 89-92 |
  grep -v 999 |
  sort -rn |
  head -n1 > $2/max.out

hdfs dfs -cat -ignoreCrc $1 |
  cut -c 89-92 |
  grep -v 999 |
  sort -n |
  head -n1 > $2/min.out

hdfs dfs -cat -ignoreCrc $1 |
  cut -c 89-92 |
  grep -v 999 |
  awk "{ total += \$1; count++ } END { print total/count }" > $2/average.out
