package main

import (
	"bufio"
	"context"
	"encoding/binary"
	"errors"
	"flag"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"strings"
	"time"

	pb "runtime/pipe/proto"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	"github.com/google/uuid"
)

var (
	streamType = flag.String("type", "", "Either read/write")
	serverAddr = flag.String("addr", "localhost:50052", "The server address in the format of host:port")
	streamId   = flag.String("id", "", "The id of the stream")
	debug      = flag.Bool("d", false, "Turn on debugging messages")
	chunkSize  = flag.Int("chunk_size", 4096, "The chunk size for the rpc stream")
	_          = flag.String("kill", "", "Kill the node at the given address")
	ft         = flag.String("ft", "disabled", "Fault tolerance mode. naive, base or optimized. Default is disabled")
)

const eof uint64 = 0xd1d2d3d4d5d6d7d8

func getAddr(client pb.DiscoveryClient, optimized bool) (string, error) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	var reply *pb.GetAddrReply
	var err error
	if optimized {
		reply, err = client.GetAddrOptimized(ctx, &pb.AddrReq{Id: *streamId})
	} else {
		reply, err = client.GetAddr(ctx, &pb.AddrReq{Id: *streamId})
	}
	if err == nil {
		log.Printf("GetAddr: found %v\n", reply)
		return reply.Addr, nil
	}
	return "", err
}

func removeAddr(client pb.DiscoveryClient) {
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()

	_, err := client.RemoveAddr(ctx, &pb.AddrReq{Id: *streamId})
	log.Printf("Remove id %v returned %v", *streamId, err)
}

func readWrapper(client pb.DiscoveryClient, numRetry int, ft string) (n int, err error) {
	for i := 0; i < numRetry; i++ {
		var nn int
		if ft == "optimized" {
			nn, err = readOptimized(client, n)
		} else {
			nn, err = read(client, n, ft == "disabled")
		}
		n += nn
		if err == nil {
			break
		}
		log.Println("read failed because:", err, "retrying:", i+1, "will skip:", n)
		time.Sleep(1 * time.Second)
	}
	return
}

func read(client pb.DiscoveryClient, skip int, skipEof bool) (int, error) {
	addr, err := getAddr(client, false)
	if err != nil {
		return 0, err
	}

	conn, err := net.Dial("tcp4", addr)
	if err != nil {
		return 0, err
	}
	defer conn.Close()
	log.Printf("successfuly dialed to %v\n", addr)

	if skipEof {
		reader := bufio.NewReader(conn)
		n, err := reader.WriteTo(os.Stdout)
		return int(n), err
	}

	buf := make([]byte, *chunkSize)
	writer := bufio.NewWriter(os.Stdout)
	defer writer.Flush()
	written := 0
	exit := false

	// read first 8 bytes
	_, err = io.ReadFull(conn, buf[:8])
	if err != nil {
		return 0, errors.New("read eof failure: too few bytes read" + err.Error())
	}

	for {
		// read to after 8th byte in buffer
		n, err := conn.Read(buf[8:])
		if err != nil {
			if err == io.EOF {
				exit = true
			} else {
				return written, err
			}
		}

		var nn int
		if skip == 0 {
			// write except for the last 8 bytes
			nn, err = writer.Write(buf[:n])
		} else if skip < n {
			// write except for the last 8 bytes, skip first skip bytes
			nn, err = writer.Write(buf[skip:n])
			skip = 0
		} else {
			// write nothing, reduce skip by n
			nn = 0
			skip -= n
		}

		written += nn
		if err != nil {
			return written, err
		}

		if exit {
			if binary.BigEndian.Uint64(buf[n:n+8]) != eof {
				return written, errors.New("read eof failure: token doesn't match")
			}
			return written, nil
		}

		// copy last 8 bytes to the beginning of the buffer
		// we start from
		copy(buf, buf[n:n+8])
	}
}

func readOptimized(client pb.DiscoveryClient, skip int) (int, error) {
	addr, err := getAddr(client, true)
	if err != nil {
		return 0, err
	}

	parts := strings.Split(addr, ",")
	host := parts[0]
	path := parts[1]

	addr = fmt.Sprintf("%s:%d", host, 50053)
	conn, err := net.Dial("tcp4", addr)
	if err != nil {
		return 0, err
	}
	defer conn.Close()

	message := fmt.Sprintf("%s:%d:%s", path, skip, *streamId)
	_, err = conn.Write([]byte(message))
	if err != nil {
		return 0, err
	}

	buf := make([]byte, *chunkSize)
	writer := bufio.NewWriter(os.Stdout)
	defer writer.Flush()
	written := 0
	exit := false

	// read first 8 bytes
	_, err = io.ReadFull(conn, buf[:8])
	if err != nil {
		return 0, errors.New("read eof failure: too few bytes read" + err.Error())
	}

	for {
		// read to after 8th byte in buffer
		n, err := conn.Read(buf[8:])
		if err != nil {
			if err == io.EOF {
				exit = true
			} else {
				return written, err
			}
		}

		var nn int
		// write except for the last 8 bytes
		// we treat skip here as 0 because we already seeked the position in filereder
		nn, err = writer.Write(buf[:n])

		written += nn
		if err != nil {
			return written, err
		}

		if exit {
			if binary.BigEndian.Uint64(buf[n:n+8]) != eof {
				return written, errors.New("read eof failure: token doesn't match")
			}
			return written, nil
		}

		// copy last 8 bytes to the beginning of the buffer
		// we start from
		copy(buf, buf[n:n+8])
	}
}

func write(client pb.DiscoveryClient, skipEof bool) (int, error) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	host, err := os.Hostname()
	if err != nil {
		return 0, err
	}

	ips, err := net.LookupIP(host)
	if err != nil {
		return 0, err
	}

	host = ips[0].String()

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

	writer := bufio.NewWriter(conn)
	defer writer.Flush()

	n, err := writer.ReadFrom(os.Stdin)
	if err != nil {
		return int(n), err
	}

	if !skipEof {
		err = binary.Write(writer, binary.BigEndian, eof)
	}

	return int(n), err
}

func writeOpimized(client pb.DiscoveryClient) (int, error) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Retrieve the FISH_OUT_PREFIX environment variable
	fishOutPrefix := os.Getenv("FISH_OUT_PREFIX")

	// Check if the variable is set
	if fishOutPrefix == "" {
		return 0, errors.New("FISH_OUT_PREFIX environment variable is not set")
	}

	file, err := os.CreateTemp(fishOutPrefix, "datastream-")
	if err != nil {
		return 0, err
	}
	defer file.Close()

	host, err := os.Hostname()
	if err != nil {
		return 0, err
	}
	ips, err := net.LookupIP(host)
	if err != nil {
		return 0, err
	}
	host = ips[0].String()

	_, err = client.PutAddrOptimized(ctx, &pb.PutAddrMsg{Id: *streamId, Addr: fmt.Sprintf("%s,%s", host, file.Name())})
	if err != nil {
		return 0, err
	}

	n, err := io.Copy(file, os.Stdin)
	if err != nil {
		return 0, err
	}

	err = binary.Write(file, binary.BigEndian, eof)
	if err != nil {
		return 0, err
	}

	return int(n), err
}

func main() {
	flag.Parse()

	id, err := uuid.Parse(*streamId)
	if err != nil {
		log.Fatalf("Failed to parse uuid: %v\n", err)
	}

	b := make([]byte, 17)
	copy(b[1:], id[:])

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

	log.Println("Stream: ", *streamType, *streamId)

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
		b[0] = 0
		n, reqerr = readWrapper(client, 1000, *ft)
	} else if *streamType == "write" {
		b[0] = 1
		if *ft == "optimized" {
			n, reqerr = writeOpimized(client)
		} else {
			n, reqerr = write(client, *ft == "disabled")
		}
	} else {
		flag.Usage()
		os.Exit(1)
	}

	if reqerr != nil {
		log.Fatalln(reqerr)
	}

	log.Printf("Success %s %d bytes\n", *streamType, n)

	if *ft != "disabled" {
		// Create addr TCP connection
		addr := strings.Split(*serverAddr, ":")[0] + ":65425"
		log.Printf("Connecting to Worker Manager at %v\n", addr)
		c, err := net.Dial("tcp", addr)
		if err != nil {
			log.Fatalf("Failed to connect to Worker Manager: %v\n", err)
		}
		defer c.Close()

		// Send the request
		n, err = c.Write(b)
		if err != nil {
			log.Fatalf("Failed to send request to Worker Manager: %v\n", err)
		}

		log.Printf("Success %s %d bytes to Worker Manager\n", *streamType, n)
	}
}
