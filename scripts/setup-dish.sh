if git rev-parse --git-dir > /dev/null 2>&1; then
    export DISH_TOP=${DISH_TOP:-$(git rev-parse --show-toplevel)}
    export PASH_TOP=${PASH_TOP:-${DISH_TOP}/pash/}
else
    # set DISH_TOP to the root folder of the project if it is not available
    export DISH_TOP=${DISH_TOP:-$PWD/..}
    export PASH_TOP=${PASH_TOP:-${DISH_TOP}/pash/}
fi

## First install PaSh
"$PASH_TOP/scripts/distro-deps.sh"
"$PASH_TOP/scripts/setup-pash.sh"

# TODO: install any extra needed python deps
pip3 install flask
pip3 install matplotlib
pip3 install pandas
pip3 install seaborn
pip3 install requests --target "$PASH_TOP/python_pkgs/"

# Install Go
GO_VERSION="1.22.2"
if [ "$(uname -m)" = "x86_64" ]; then GO_ARCH="amd64"; else GO_ARCH="arm64"; fi
wget https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go${GO_VERSION}.linux-${GO_ARCH}.tar.gz
echo -e '\nexport PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
export PATH=$PATH:/usr/local/go/bin
rm go${GO_VERSION}.linux-${GO_ARCH}.tar.gz

# Protobuf
apt-get update && apt-get install -y zip
PB_REL="https://github.com/protocolbuffers/protobuf/releases"
PROTOBUF_VER="26.1"
if [ "$(uname -m)" = "x86_64" ]; then PROTOBUF_ARCH="x86_64"; else PROTOBUF_ARCH="aarch_64"; fi
PROTOBUF_PACKAGE="protoc-$PROTOBUF_VER-linux-$PROTOBUF_ARCH.zip"
curl -LO $PB_REL/download/v$PROTOBUF_VER/$PROTOBUF_PACKAGE
unzip $PROTOBUF_PACKAGE -d $HOME/.local
rm $PROTOBUF_PACKAGE
export PATH="$PATH:$HOME/.local/bin"
echo -e "\nPATH=\$PATH:$HOME/.local/bin" >> ~/.bashrc

# Go protobuf deps
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
echo -e "\nexport PATH=\$PATH:$(go env GOPATH)/bin" >> ~/.bashrc
export PATH="$PATH:$(go env GOPATH)/bin"

$DISH_TOP/runtime/scripts/build.sh

# # Compile runtime
# cd $DISH_TOP/runtime/dspash
# go build socket_pipe.go
# cd file_reader
# go build client/dfs_split_reader.go
# go build -o filereader_server server/server.go
# go build -o discovery_server server/discovery_server.go
# go build -o datastream_client client/datastream.go
