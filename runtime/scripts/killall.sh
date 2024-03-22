#!/bin/bash

# /opt/dish/runtime/scripts/killall.sh; pkill -f worker; /opt/dish/docker-hadoop/datanode/run.sh; sleep 1; ps aux
ps aux | grep -E 'dish|pash|hdfs' | grep -Ev 'killall|dish\|pash\|hdfs|worker.py' | awk '{print $2}' | xargs kill -9
