# Check if DISH_TOP is set
if [ -z "$DISH_TOP" ]
then
    # If not set, assign a default path
    export DISH_TOP=$(realpath $(dirname "$0")/../..)
fi

cd $DISH_TOP/runtime
go build -o bin/ dfs/server/filereader_server.go
go build -o bin/ dfs/client/dfs_split_reader.go
go build -o bin/ pipe/datastream/datastream.go
go build -o bin/ pipe/discovery/discovery_server.go
