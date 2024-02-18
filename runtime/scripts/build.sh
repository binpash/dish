#!/bin/bash

# Check if DISH_TOP is set
if [ -z "$DISH_TOP" ]
then
    # If not set, assign a default path
    export DISH_TOP=$(realpath $(dirname "$0")/../..)
fi

# Compile runtime
cd $DISH_TOP/runtime/dspash
go build socket_pipe.go
cd file_reader
go build client/dfs_split_reader.go
go build -o filereader_server server/server.go
go build -o discovery_server server/discovery_server.go
go build -o datastream_client client/datastream.go
