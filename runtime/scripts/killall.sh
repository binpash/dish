#!/bin/bash

ps aux | grep -E 'dish|pash|hdfs' | grep -Ev 'killall|dish\|pash\|hdfs|worker.py' | awk '{print $2}' | xargs kill -9
# ps aux | grep -E 'dish|pash|hdfs' | grep -Ev 'killall|dish\|pash\|hdfs|worker.py' | awk -v pid="$1" '{if ($2 != pid) print $2}' | xargs kill -9
