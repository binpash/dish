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
	"strconv"
	"strings"

	"google.golang.org/grpc"

	pb "runtime/dfs/proto"
)

var (
	port      = flag.Int("port", 50051, "The server port")
	chunkSize = flag.Int("chunk_size", 4*1024, "The chunk size for the rpc stream")
)

type fileReaderServer struct {
	pb.UnimplementedFileReaderServer
}

func (s *fileReaderServer) ReadFile(req *pb.FileRequest, stream pb.FileReader_ReadFileServer) error {
	filename, err := pb.GetAbsPath(req.Path)
	if err != nil {
		log.Println(err)
		return err
	}

	file, err := os.Open(filename)
	if err != nil {
		log.Println(err)
		return err
	}
	defer file.Close()

	reader := bufio.NewReader(file)
	buffer := make([]byte, *chunkSize)
	for {
		n, err := reader.Read(buffer)
		stream.Send(&pb.ReadReply{Buffer: buffer[:n]})

		if err == io.EOF {
			break
		}

		if err != nil {
			return err
		}
	}

	return nil
}

func (s *fileReaderServer) ReadNewLine(ctx context.Context, req *pb.FileRequest) (*pb.ReadReply, error) {
	filename, err := pb.GetAbsPath(req.Path)
	if err != nil {
		log.Println("fr exit3", err)
		return &pb.ReadReply{}, err
	}

	file, err := os.Open(filename)
	if err != nil {
		log.Println("fr exit4", req.Path, filename, err)
		return &pb.ReadReply{}, err
	}
	defer file.Close()

	reader := bufio.NewReader(file)
	line, err := reader.ReadBytes('\n')
	if err != nil {
		log.Println("fr exit5", err)
		return &pb.ReadReply{}, err
	}

	return &pb.ReadReply{Buffer: line}, nil
}

func (s *fileReaderServer) ReadFileFull(ctx context.Context, req *pb.FileRequest) (*pb.ReadReply, error) {
	filepath := req.Path
	file, err := os.Open(filepath)
	if err != nil {
		log.Println("fr exit1", err)
		return &pb.ReadReply{}, err
	}
	defer file.Close()

	data, err := io.ReadAll(file)
	if err != nil {
		log.Println("fr exit1", err)
		return &pb.ReadReply{}, err
	}

	return &pb.ReadReply{Buffer: data}, nil
}

func handleConnection(conn net.Conn) {
	defer conn.Close()

	// Read the message from the connection, assuming message is less than 1024 bytes
	buffer := make([]byte, 1024)

	n, err := conn.Read(buffer)
	if err != nil {
		log.Println("FR: Error reading from connection:", err)
		return
	}

	message := string(buffer[:n])

	// Split message into filepath, seek and id by ":"
	parts := strings.Split(message, ":")
	filepath := parts[0]
	seek, err := strconv.ParseInt(parts[1], 10, 64)
	if err != nil {
		log.Println("FR: Invalid seek value:", err)
		return
	}
	pattern := "datastream --type write --id " + parts[2]

	// Open the file
	file, err := os.Open(filepath)
	if err != nil {
		log.Println("FR: Error opening file:", err)
		return
	}
	defer file.Close()

	// Seek to the specified position
	file.Seek(seek, 0)

	// Transfer the file content to the socket using io.Copy
	_, err = io.Copy(conn, file)
	if err != nil {
		log.Println("FR: Error transferring file:", err)
		return
	}

	// for {
	// 	_, err = io.Copy(conn, file)
	// 	if err != nil {
	// 		log.Println("FR: Error transferring file:", err)
	// 		return
	// 	}

	// 	processExists, err := processExists(pattern)
	// 	if err != nil {
	// 		log.Println("FR: Error checking if process exists:", err)
	// 		return
	// 	}

	// 	// log.Println("FR: Process exists:", processExists, pattern)

	// 	if !processExists {
	// 		break
	// 	}

	// 	time.Sleep(1 * time.Second)
	// }
}

func processExists(pattern string) (bool, error) {
	// Execute the pgrep command with the given pattern
	cmd := exec.Command("pgrep", "-f", pattern)
	output, err := cmd.CombinedOutput()

	// Check if the command ran successfully
	if err != nil {
		// If there is an error, check if it's because no process matched the pattern
		if exitError, ok := err.(*exec.ExitError); ok && exitError.ExitCode() == 1 {
			// Exit code 1 means no process matched the pattern
			return false, nil
		}
		// If it's another error, return it
		return false, err
	}

	// Check if the output is empty
	if strings.TrimSpace(string(output)) == "" {
		return false, nil
	}

	// If there is output, it means a process was found
	return true, nil
}

func fileTransmitter() {
	host, err := os.Hostname()
	if err != nil {
		log.Fatalln("FR: failed to get hostname:", err)
	}

	ips, err := net.LookupIP(host)
	if err != nil {
		log.Fatalln("FR: failed to get IP:", err)
	}

	host = ips[0].String()

	ln, err := net.Listen("tcp4", host+":50053") // 50051 is FR adn 50052 is DS
	if err != nil {
		log.Fatalln("FR: failed to listen:", err)
	}
	defer ln.Close()

	addr := ln.Addr().String()
	log.Println("FR: file transmitter listening in", addr)

	for {
		// Wait for a connection.
		conn, err := ln.Accept()
		if err != nil {
			log.Println("Error accepting connection:", err)
			continue
		}

		// Handle the connection in a new goroutine.
		go handleConnection(conn)
	}
}

func newServer() *fileReaderServer {
	s := &fileReaderServer{}
	return s
}

func main() {
	flag.Parse()
	lis, err := net.Listen("tcp", fmt.Sprintf("0.0.0.0:%d", *port))
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}

	go fileTransmitter()

	var opts []grpc.ServerOption
	grpcServer := grpc.NewServer(opts...)
	pb.RegisterFileReaderServer(grpcServer, newServer())
	fmt.Printf("File server running on %v\n", lis.Addr())
	grpcServer.Serve(lis)
}
