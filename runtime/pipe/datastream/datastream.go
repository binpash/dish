package main

import (
	"bufio"
	"bytes"
	"context"
	"encoding/binary"
	"errors"
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
	streamType        = flag.String("type", "", "Either read/write")
	serverAddr        = flag.String("addr", "localhost:50052", "The server address in the format of host:port")
	streamId          = flag.String("id", "", "The id of the stream")
	debug             = flag.Bool("d", false, "Turn on debugging messages")
	chunkSize         = flag.Int("chunk_size", 4096, "The chunk size for the rpc stream")
	killAddr          = flag.String("kill", "", "Kill the node at the given address")
	managerServerAddr = flag.String("managerAddr", "addr:50052", "The server address on nodemanager node in the format of host:port")
)

const eof uint64 = 0xd1d2d3d4d5d6d7d8

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
		case <-time.After(time.Millisecond * 1000):
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

func readWrapper(client pb.DiscoveryClient, numRetry int) (n int, err error) {
	for i := 0; i < numRetry; i++ {
		nn, err := read(client)
		n += nn
		if err == nil {
			break
		}
		// log.Println("read failed because:", err, "retrying:", i+1, "will skip:", n)
		time.Sleep(1 * time.Second)
	}
	return
}

func read(client pb.DiscoveryClient) (int, error) {
	timeout := 10 * time.Second
	var (
		addr string
		conn net.Conn
		err  error
	)

	// Keep trying to connect to the writer if failed
	// This logic may not be necessary with the readWrapper handling re-tries
	totimer := time.NewTimer(timeout)
	defer totimer.Stop()
loop:
	for {
		select {
		case <-totimer.C:
			// Timeout occurred
			return 0, errors.New("connection timed out")
		default:
			addr, err = getAddr(client, timeout)
			if err != nil {
				log.Printf("err %v\n", err)
				time.Sleep(300 * time.Millisecond)
				continue
			} else {
				conn, err = net.Dial("tcp4", addr)
				if err != nil {
					log.Printf("err %v\n", err)
					time.Sleep(300 * time.Millisecond)
					continue
				} else {
					log.Printf("successfuly dialed to %v\n", addr)
					break loop
				}
			}
		}
	}
	defer conn.Close()

	// maybe limit recursion here?
	var buf bytes.Buffer
	n, err := buf.ReadFrom(conn)
	log.Printf("buffer size: %v\n", buf.Len())
	if err != nil || n < 8 {
		log.Println("re-reading, previous read failed because:", err, n)
		nn, err := read(client)
		return nn, err
	}

	if binary.LittleEndian.Uint64(buf.Bytes()[n-8:n]) != eof {
		log.Println("re-reading, previous read failed because eof not found")
		nn, err := read(client)
		return nn, err
	}

	nn, err := os.Stdout.Write(buf.Bytes()[:n-8])

	return nn, err
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
	log.Println("accepted a connection")

	if *killAddr == strings.Split(conn.LocalAddr().String(), ":")[0] {
		kill(conn)
	}

	writer := bufio.NewWriter(conn)
	defer writer.Flush()

	n, err := writer.ReadFrom(os.Stdin)
	if err != nil {
		return int(n), err
	}

	// var i uint32 = 0x01020304
	// b := make([]byte, 4)
	// binary.LittleEndian.PutUint32(b, i)

	// if b[0] == 0x04 {
	// 	log.Println("Little Endian")
	// } else if b[0] == 0x01 {
	// 	log.Println("Big Endian")
	// } else {
	// 	log.Println("Unknown Endian")
	// }

	err = binary.Write(writer, binary.LittleEndian, eof)

	return int(n), err
}

func kill(conn net.Conn) {
	buf := make([]byte, *chunkSize)
	n, err := os.Stdin.Read(buf)

	if err != nil && err != io.EOF {
		log.Fatal(err)
	}

	// we don't write everything here, thats why we use n/2 instead of n
	n /= 2
	n, err = conn.Write(buf[:n])
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("killing myself after writing %v bytes\n", n)

	ex, _ := os.Executable()
	exPath := filepath.Dir(ex)
	scriptPath := filepath.Join(exPath, "../scripts/killall.sh")
	cmd := exec.Command("/bin/sh", scriptPath)
	err = cmd.Run()
	if err != nil {
		log.Fatal(err)
	}
	os.Exit(1)
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

	log.Printf("Connecting to Discovery Service at %v\n", *managerServerAddr)
	conn, err := grpc.Dial(*managerServerAddr, opts...)
	if err != nil {
		log.Fatalf("Failed to connect to grpc server: %v\n", err)
	}
	defer conn.Close()
	client := pb.NewDiscoveryClient(conn)

	var reqerr error
	var n int
	if *streamType == "read" {
		n, reqerr = readWrapper(client, 20)
		// n, reqerr = read(client)
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
