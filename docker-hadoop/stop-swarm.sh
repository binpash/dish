#!/bin/bash
docker stack rm hadoop
docker service rm registry
docker network rm hbase