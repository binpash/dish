#!/bin/bash

# pkill -9 -f discovery_server
# pkill -9 -f filereader_server
# pkill -9 -f datastream
# pkill -9 -f worker.py
# pkill -9 -f worker.sh
# pkill -9 -f hdfs 

ps aux | grep -E 'dish|pash|hdfs' | grep -Ev 'killall|dish\|pash\|hdfs|worker.py' | awk '{print $2}' | xargs kill -9
