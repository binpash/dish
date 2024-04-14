package main

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"strings"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	pb "runtime/dfs/proto"
)

var (
	config         = flag.String("config", "", "File to read")
	splitNum       = flag.Int("split", 0, "The logical split number")
	serverPort     = flag.Int("port", 50051, "The server port, all machines should use same port")
	ft             = flag.String("ft", "", "The fault tolerance mode")
	path           = flag.String("path", "", "The path of the block")
	subblockNum    = flag.Int("subblockNum", 0, "The sub split number")
	subblockCnt    = flag.Int("subblockCnt", 1, "The total count of subblocks in one block")
	nextBlockPath  = flag.String("nextBlockPath", "", "The path of the next block")
	nextBlockHosts = flag.String("nextBlockHosts", "", "The hosts of the next block")
)

// Distrubted file system block
type DFSBlock struct {
	Path  string
	Hosts []string
}

// Distributed file system config
type DFSConfig struct {
	Blocks []DFSBlock
}

// very important
// TODO: improve so that we don't use network if block is replicated on the same machine
func readFirstLine(block DFSBlock, writer *bufio.Writer) (ok bool, e error) {
	var opts []grpc.DialOption
	opts = append(opts, grpc.WithTransportCredentials(insecure.NewCredentials()))
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	ok = false
	e = errors.New("failed to read newline from all replicas")
	for _, host := range block.Hosts {
		addr := fmt.Sprintf("%s:%d", host, *serverPort)
		conn, err := grpc.Dial(addr, opts...)

		if err != nil {
			continue // try next addr
		}
		defer conn.Close()

		client := pb.NewFileReaderClient(conn)

		stream, err := client.ReadFile(ctx, &pb.FileRequest{Path: block.Path})
		if err != nil {
			continue
		}

		for {
			reply, err := stream.Recv()
			if err == io.EOF {
				return ok, err
			}
			if err != nil {
				// Can't recover because we already wrote some bytes.
				// TODO: recover by using intermediate buffer or adding rpcs to allow
				// 		discarding on server side
				return ok, err
			}
			for _, byt := range reply.Buffer {
				err := writer.WriteByte(byt)
				if err != nil {
					return
				}
				if byt == '\n' {
					return true, nil
				}
			}
		}
	}
	return
}

func readLocalFile(p string, skipFirstLine bool, writer *bufio.Writer) error {
	file, err := os.Open(p)
	if err != nil {
		return err
	}
	defer file.Close()

	reader := bufio.NewReader(file)

	if skipFirstLine {
		_, err = reader.ReadString('\n') //discarded
		if err != nil {
			return err
		}
	}

	io.Copy(writer, reader)

	return nil
}

func readDFSLogicalSplit(conf DFSConfig, split int) error {

	skipFirstLine := true
	writer := bufio.NewWriter(os.Stdout)
	defer writer.Flush()

	if split == 0 {
		skipFirstLine = false
	}

	filepath, err := pb.GetAbsPath(conf.Blocks[split].Path)
	if err != nil {
		return err
	}

	err = readLocalFile(filepath, skipFirstLine, writer)
	if err != nil {
		return err
	}

	// Read until newline
	for _, block := range conf.Blocks[split+1:] {
		done, err := readFirstLine(block, writer)
		if !done {
			if err == io.EOF {
				continue // read next block if first one didn't contain newline
			} else {
				return err
			}
		} else {
			break
		}
	}
	return nil

}

func readLogicalSplitOptimized(
	splitNum int,
	path string,
	subblockNum int,
	subblockCnt int,
	nextBlockPath string,
	nextBlockHosts string,
) error {
	filepath, err := pb.GetAbsPath(path)
	if err != nil {
		return err
	}

	file, err := os.Open(filepath)
	if err != nil {
		return err
	}

	fileInfo, err := file.Stat()
	if err != nil {
		return err
	}

	fileSize := fileInfo.Size()
	partSize := fileSize/int64(subblockCnt) + 1
	startOffset := int64(subblockNum) * partSize

	_, err = file.Seek(startOffset, 0) // Seek to the offset
	if err != nil {
		return err
	}

	defer file.Close()

	partReader := io.LimitReader(file, partSize)
	reader := bufio.NewReader(partReader)

	// skip first line
	if splitNum+subblockNum > 0 {
		// discarded
		_, err = reader.ReadBytes('\n')
		if err != nil {
			return err
		}
	}

	writer := bufio.NewWriter(os.Stdout)
	defer writer.Flush()

	_, err = io.Copy(writer, reader)
	if err != nil {
		return err
	}

	var nextLine []byte
	if subblockNum < subblockCnt-1 {
		reader = bufio.NewReader(file)
		nextLine, err = reader.ReadBytes('\n')
		if err != nil {
			return err
		}
	} else {
		for _, host := range strings.Split(nextBlockHosts, ",") {
			addr := fmt.Sprintf("%s:%d", host, *serverPort)
			conn, err := grpc.Dial(addr, grpc.WithInsecure())
			if err != nil {
				continue
			}
			defer conn.Close()

			client := pb.NewFileReaderClient(conn)
			reply, err := client.ReadNewLine(context.Background(), &pb.FileRequest{Path: nextBlockPath})
			if err != nil {
				continue
			}

			nextLine = reply.Buffer
			break
		}
	}

	// write next line
	_, err = writer.Write(nextLine)
	if err != nil {
		return err
	}

	return nil
}

func serialize_conf(p string) DFSConfig {
	conf := DFSConfig{}
	byt, err := os.ReadFile(p)
	if err != nil {
		log.Fatalln(err)
	}
	if err := json.Unmarshal(byt, &conf); err != nil {
		log.Fatalln(err)
	}
	return conf
}

func main() {
	flag.Parse()
	if flag.NArg() < 1 && *config == "" {
		flag.Usage()
		os.Exit(0)
	} else if *config == "" {
		*config = flag.Arg(0)
	}

	// Print all flags
	// flag.VisitAll(func(f *flag.Flag) {
	// 	log.Printf("Flag %s: %v\n", f.Name, f.Value)
	// })

	var err error
	if *ft == "optimized" {
		err = readLogicalSplitOptimized(*splitNum, *path, *subblockNum, *subblockCnt, *nextBlockPath, *nextBlockHosts)
	} else {
		conf := serialize_conf(*config)
		err = readDFSLogicalSplit(conf, *splitNum)
	}

	if err != nil {
		log.Fatalln(err)
	}
}
