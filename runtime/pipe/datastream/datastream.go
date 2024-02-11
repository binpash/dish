package main

import (
	"bufio"
	"context"
	"flag"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	pb "runtime/pipe/proto"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

var (
	streamType = flag.String("type", "", "Either read/write")
	serverAddr = flag.String("addr", "localhost:50052", "The server address in the format of host:port")
	streamId   = flag.String("id", "", "The id of the stream")
	debug      = flag.Bool("d", false, "Turn on debugging messages")
	chunkSize  = flag.Int("chunk_size", 4*1024, "The chunk size for the rpc stream")
	killTarget = flag.String("kill", "", "Kill the node at the given address")
)

func getAddr(client pb.DiscoveryClient, timeout time.Duration) (string, error) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	totimer := time.NewTimer(timeout)
	defer totimer.Stop()
	for {
		reply, err := client.GetAddr(ctx, &pb.AddrReq{Id: *streamId})
		if err == nil {
			log.Printf("GetAddr: found %v\n", reply)
			return reply.Addr, nil
		}
		select {
		case <-time.After(time.Millisecond * 100):
			log.Printf("%s retrying to connect\n", err)
			continue
		case <-totimer.C:
			return "", err
		}
	}
}

func removeAddr(client pb.DiscoveryClient) {
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()

	_, err := client.RemoveAddr(ctx, &pb.AddrReq{Id: *streamId})
	log.Printf("Remove id %v returned %v", *streamId, err)
}

func poisonPill() {
	log.Println("Received poison pill")
	ex, _ := os.Executable()
	exPath := filepath.Dir(ex)
	scriptPath := filepath.Join(exPath, "../scripts/killall.sh")
	err := exec.Command("bash", scriptPath).Start()
	if err != nil {
		log.Println("Error running killall script", err)
	}
}

func read(client pb.DiscoveryClient) (int, error) {
	timeout := 10 * time.Second
	addr, err := getAddr(client, timeout)
	if err != nil {
		return 0, err
	}

	conn, err := net.Dial("tcp4", addr)
	if err != nil {
		return 0, err
	}
	defer conn.Close()
	log.Printf("successfuly dialed to %v\n", addr)

	reader := bufio.NewReader(conn)
	// n, err := reader.WriteTo(os.Stdout)

	chunkSize64 := int64(*chunkSize)
	var total int64 = 0

	for {
		n, err := io.CopyN(os.Stdout, reader, chunkSize64)
		total += n
		if err != nil {
			break
		}

		b, err := reader.ReadByte()
		if err != nil {
			break
		}
		total++

		if b == 1 {
			poisonPill()
			break
		}
	}

	if err == io.EOF {
		err = nil
	}

	return int(total), err
}

func write(client pb.DiscoveryClient) (int, error) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	host := strings.Split(*serverAddr, ":")[0]

	ln, err := net.Listen("tcp4", host+":0") // connect to random port
	if err != nil {
		return 0, err
	}
	defer ln.Close()

	addr := ln.Addr().String()
	log.Printf("listening to %v\n", addr)

	ret, err := client.PutAddr(ctx, &pb.PutAddrMsg{Id: *streamId, Addr: addr})
	if err != nil {
		return 0, err
	}
	defer removeAddr(client)
	log.Printf("put %v %v\n", addr, ret)

	conn, err := ln.Accept()
	if err != nil {
		return 0, err
	}
	defer conn.Close()
	log.Println("accepted a connection", conn.RemoteAddr())

	writer := bufio.NewWriter(conn)
	defer writer.Flush()

	chunkSize64 := int64(*chunkSize)
	var total int64 = 0

	isKillTarget := *killTarget == strings.Split(conn.RemoteAddr().String(), ":")[0]
	// shouldSuicide := *killTarget == strings.Split(conn.LocalAddr().String(), ":")[0]

	for {
		n, err := io.CopyN(writer, os.Stdin, chunkSize64)
		total += n
		if err != nil {
			break
		}

		// if shouldSuicide {
		// 	log.Println("Swallowing poison pill")
		// 	poisonPill()
		// 	err = writer.WriteByte(0)
		// }

		if isKillTarget {
			log.Println("Sending poison pill to", *killTarget)
			err = writer.WriteByte(1)
		} else {
			err = writer.WriteByte(0)
		}

		if err != nil {
			break
		}
		total++
	}

	if err == io.EOF {
		err = nil
	}

	// n, err := writer.ReadFrom(os.Stdin)
	return int(total), err
}

// TODO: readStream/writeStream are buggy but also not used so low priority.
func readStream(client pb.DiscoveryClient) (n int, err error) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	n = 0
	stream, err := client.ReadStream(ctx, &pb.AddrReq{Id: *streamId})
	if err != nil {
		return
	}

	writer := bufio.NewWriter(os.Stdout)
	defer writer.Flush()

	for {
		reply, err := stream.Recv()
		if err == io.EOF {
			return n, nil
		}

		if err != nil {
			return n, err
		}

		nn, err := writer.Write(reply.Buffer)
		n += nn
	}
}

func writeStream(client pb.DiscoveryClient) (n int, err error) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	n = 0
	stream, err := client.WriteStream(ctx)
	if err != nil {
		return
	}
	// First message
	stream.Send(&pb.Data{Id: *streamId})

	reader := bufio.NewReader(os.Stdin)
	buffer := make([]byte, *chunkSize)
	for {
		nn, err := reader.Read(buffer)
		if err != nil {
			if err == io.EOF {
				_, err = stream.CloseAndRecv()
			}
			return n, err
		}
		stream.Send(&pb.Data{Buffer: buffer})
		n += nn
	}
}

func logFlagValues() {
	var flags string
	flag.VisitAll(func(f *flag.Flag) {
		flags += fmt.Sprintf(" %s", f.Value.String())
	})
	log.Printf("Flag values:%s\n", flags)
}

func main() {
	flag.Parse()
	arg_idx := 0
	if *streamType == "" {
		*streamType = flag.Arg(arg_idx)
		arg_idx += 1
	}

	if *streamId == "" {
		*streamId = flag.Arg(arg_idx)
		arg_idx += 1
	}

	if !*debug {
		log.SetOutput(io.Discard)
	} else {
		log.SetFlags(log.Flags() | log.Lmsgprefix)
		log.SetPrefix(fmt.Sprintf("%v %v client ", (*streamId)[0:8], *streamType))
	}

	logFlagValues()

	var opts []grpc.DialOption
	opts = append(opts, grpc.WithTransportCredentials(insecure.NewCredentials()))

	log.Printf("Connecting to Discovery Service at %v\n", *serverAddr)
	conn, err := grpc.Dial(*serverAddr, opts...)
	if err != nil {
		log.Fatalf("Failed to connect to grpc server: %v\n", err)
	}
	defer conn.Close()
	client := pb.NewDiscoveryClient(conn)

	var reqerr error
	var n int
	if *streamType == "read" {
		n, reqerr = read(client)
	} else if *streamType == "write" {
		n, reqerr = write(client)
	} else {
		flag.Usage()
		os.Exit(1)
	}

	if reqerr != nil {
		log.Fatalln(reqerr)
	}

	log.Printf("Success %s %d bytes\n", *streamType, n)
}
