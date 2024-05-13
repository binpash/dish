#!/bin/bash

hdfs dfs -cat -ignoreCrc $1 | sort
