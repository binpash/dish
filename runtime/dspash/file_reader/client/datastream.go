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
	"strings"
	"time"

	pb "dspash/datastream"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

var (
	streamType      = flag.String("type", "", "Either read/write/update")
	serverAddr      = flag.String("addr", "localhost:50052", "The server address in the format of host:port")
	localServerAddr = flag.String("localAddr", "", "The local server address in the format of host:port")
	streamId        = flag.String("id", "", "The id of the stream")
	debug           = flag.Bool("d", false, "Turn on debugging messages")
	chunkSize       = flag.Int("chunk_size", 4*1024, "The chunk size for the rpc stream")
	oldServerAddr   = flag.String("oldAddr", "", "The local server address in the format of host:port")
	newServerAddr   = flag.String("newAddr", "", "The local server address in the format of host:port")
)

func getClientForGlobal(clientForLocal pb.DiscoveryClient) (*grpc.ClientConn, pb.DiscoveryClient, error) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Get latest address
	reply, err := clientForLocal.GetLatestWriterServerAddr(ctx, &pb.GetLatestWriterServerAddrReq{Id: *streamId, WriterServerAddr: *serverAddr})
	if err != nil {
		log.Fatalf("Failed to get latest server addr: %v\n", err)
	}
	serverAddr = &reply.Addr
	var opts []grpc.DialOption
	opts = append(opts, grpc.WithTransportCredentials(insecure.NewCredentials()))
	// log.Printf("Connecting to Discovery Service at %v\n", *serverAddr)
	conn, err := grpc.Dial(*serverAddr, opts...)
	if err != nil {
		log.Fatalf("Failed to connect to grpc server: %v\n", err)
		return nil, nil, err
	}
	clientForGlobal := pb.NewDiscoveryClient(conn)
	return conn, clientForGlobal, nil
}

func getAddr(client pb.DiscoveryClient) (string, error) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	log.Printf("Before calling GetAddr for id %v\n", *streamId)
	reply, err := client.GetAddr(ctx, &pb.AddrReq{Id: *streamId})
	if err == nil {
		log.Printf("GetAddr: found %v\n", reply)
		return reply.Addr, nil
	}
	return "", err
}

func removeAddr(client pb.DiscoveryClient) {
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	// ctx, cancel := context.WithCancel(context.Background())
	// defer cancel()

	_, err := client.RemoveAddr(ctx, &pb.AddrReq{Id: *streamId})
	log.Printf("Remove id %v returned %v", *streamId, err)
}

func read(client pb.DiscoveryClient) (int, error) {
	var addr string
	for {
		connForGlobalServer, clientForGlobalServer, err := getClientForGlobal(client)
		defer connForGlobalServer.Close()

		if err != nil {
			return 0, err
		}
		log.Printf("Successfully connected to Discovery Service at %v\n", *serverAddr)
		addr, err = getAddr(clientForGlobalServer)
		if err != nil {
			log.Printf("err %v\n", err)
			time.Sleep(300 * time.Millisecond)
			continue
		} else {
			break
		}
	}

	conn, err := net.Dial("tcp4", addr)
	if err != nil {
		return 0, err
	}
	defer conn.Close()
	log.Printf("successfully dialed to %v\n", addr)

	reader := bufio.NewReader(conn)
	n, err := reader.WriteTo(os.Stdout)

	return int(n), err
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

	n, err := writer.ReadFrom(os.Stdin)

	return int(n), err
}

func update(client pb.DiscoveryClient, oldDiscoveryServerAddr string, newDiscoveryServerAddr string) error {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	log.Printf("update is called!")
	reply, err := client.UpdateWriterServerAddr(ctx,
		&pb.UpdateWriterServerAddrReq{Id: *streamId, OldAddr: oldDiscoveryServerAddr, NewAddr: newDiscoveryServerAddr})
	if err == nil {
		log.Printf("update: found %v\n", reply)
		return nil
	}

	return err
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

	return
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

	var opts []grpc.DialOption
	opts = append(opts, grpc.WithTransportCredentials(insecure.NewCredentials()))

	var addr *string
	if *localServerAddr == "" {
		addr = serverAddr
	} else {
		addr = localServerAddr
	}
	log.Printf("Connecting to Discovery Service at %v\n", *addr)
	conn, err := grpc.Dial(*addr, opts...)
	if err != nil {
		log.Fatalf("Failed to connect to grpc server: %v\n", err)
	}
	defer conn.Close()
	clientForLocal := pb.NewDiscoveryClient(conn)

	var reqerr error
	var n int
	if *streamType == "read" {
		n, reqerr = read(clientForLocal)
	} else if *streamType == "write" {
		n, reqerr = write(clientForLocal)
	} else if *streamType == "update" {
		reqerr = update(clientForLocal, *oldServerAddr, *newServerAddr)
	} else {
		flag.Usage()
		os.Exit(1)
	}

	if reqerr != nil {
		log.Fatalln(reqerr)
	}
	if *streamType == "read" || *streamType == "write" {
		log.Printf("Success %s %d bytes\n", *streamType, n)
	} else {
		log.Printf("Success %s", *streamType)
	}
}
