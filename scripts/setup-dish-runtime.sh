# Compile runtime
cd $DISH_TOP/runtime/dspash
go build socket_pipe.go
cd file_reader
go build client/dfs_split_reader.go
go build -o filereader_server server/server.go
go build -o discovery_server server/discovery_server.go
go build -o datastream_client client/datastream.go