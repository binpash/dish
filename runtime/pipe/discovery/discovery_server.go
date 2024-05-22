package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"log"
	"net"
	"strings"
	"sync"
	"time"

	"google.golang.org/grpc"

	pb "runtime/pipe/proto"
)

var (
	port          = flag.Int("port", 50052, "The server port")
	_             = flag.Int("chunk_size", 4*1024, "The chunk size for the rpc stream")
	streamTimeout = flag.Int("t", 10, "Wait period in seconds before we give up")
)

type DiscoveryServer struct {
	pb.UnimplementedDiscoveryServer
	addrs   map[string]string
	chans   map[string]chan string
	streams map[string]chan []byte
	mu      sync.Mutex // protects addrs
}

func (s *DiscoveryServer) PutAddr(ctx context.Context, msg *pb.PutAddrMsg) (*pb.Status, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	addr, id := msg.Addr, msg.Id
	// we let the workers overwrite the address
	// if _, ok := s.addrs[id]; ok {
	// 	return &pb.Status{Success: false}, errors.New("PutAddr: id already inserted\n")
	// }

	s.addrs[id] = addr
	return &pb.Status{Success: true}, nil
}

func (s *DiscoveryServer) GetAddr(ctx context.Context, msg *pb.AddrReq) (*pb.GetAddrReply, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	addr, ok := s.addrs[msg.Id]
	if !ok {
		return &pb.GetAddrReply{Success: false}, errors.New("GetAddr: id not found, retry in a little bit")
	}

	return &pb.GetAddrReply{Success: true, Addr: addr}, nil
}

func (s *DiscoveryServer) RemoveAddr(ctx context.Context, msg *pb.AddrReq) (*pb.Status, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	_, ok := s.addrs[msg.Id]
	if !ok {
		return &pb.Status{Success: false}, errors.New("RemoveAddr: id not found")
	}

	delete(s.addrs, msg.Id)
	return &pb.Status{Success: true}, nil
}

func (s *DiscoveryServer) PutAddrOptimized(ctx context.Context, msg *pb.PutAddrMsg) (*pb.Status, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	addr, id := msg.Addr, msg.Id
	c, ok := s.chans[id]
	if ok {
		c <- addr
		delete(s.chans, id)
	}
	s.addrs[id] = addr

	return &pb.Status{Success: true}, nil
}

func (s *DiscoveryServer) GetAddrOptimized(ctx context.Context, msg *pb.AddrReq) (*pb.GetAddrReply, error) {
	s.mu.Lock()

	addr, ok := s.addrs[msg.Id]
	var c chan string
	if !ok {
		c = make(chan string)
		s.chans[msg.Id] = c
	}

	s.mu.Unlock()

	if !ok {
		addr = <-c
	}

	return &pb.GetAddrReply{Success: true, Addr: addr}, nil
}

func (s *DiscoveryServer) FindPersistedOptimized(ctx context.Context, msg *pb.FPMessage) (*pb.FPMessageReply, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	var reply []int32

	for i, u := range msg.Uuids {
		if merged, ok := s.addrs[u]; ok {
			host := strings.Split(merged, ",")[0]
			if host != msg.Addr {
				reply = append(reply, int32(i))
			} else {
				delete(s.addrs, u)
				if c, ok := s.chans[u]; ok {
					c <- "error"
					delete(s.chans, u)
				}
			}
		}
	}

	return &pb.FPMessageReply{Indexes: reply}, nil
}

func (s *DiscoveryServer) RemovePersistedOptimized(ctx context.Context, msg *pb.RPMessage) (*pb.Status, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	for _, u := range msg.Uuids {
		delete(s.addrs, u)
		if c, ok := s.chans[u]; ok {
			c <- "error"
			delete(s.chans, u)
		}
	}

	return &pb.Status{Success: true}, nil
}

func (s *DiscoveryServer) ReadStream(req *pb.AddrReq, stream pb.Discovery_ReadStreamServer) error {
	totimer := time.NewTimer(time.Duration(*streamTimeout) * time.Second)
	defer totimer.Stop()
	var ch chan []byte
	for {
		s.mu.Lock()
		val, ok := s.streams[req.Id]
		s.mu.Unlock()
		if ok {
			ch = val
			break
		}
		select {
		case <-time.After(time.Millisecond * 100):
			continue
		case <-totimer.C:
			return errors.New("no writer subscribed in timeout period")
		}
	}

	for buf := range ch {
		stream.Send(&pb.Data{Buffer: buf})
	}

	return nil

}

func (s *DiscoveryServer) WriteStream(stream pb.Discovery_WriteStreamServer) error {
	data, err := stream.Recv() // first message contains id
	if err != nil {
		return err
	}

	ch := make(chan []byte)
	s.mu.Lock()
	s.streams[data.Id] = ch
	s.mu.Unlock()
	defer delete(s.streams, data.Id)

	for {
		data, err := stream.Recv()
		if err == io.EOF {
			close(ch)
			return stream.SendAndClose(&pb.Status{Success: true})
		}
		if err != nil {
			return err
		}
		ch <- data.Buffer
	}
}

func newServer() *DiscoveryServer {
	s := &DiscoveryServer{}
	s.addrs = map[string]string{}
	s.chans = map[string]chan string{}
	s.streams = map[string]chan []byte{}
	s.mu = sync.Mutex{}
	return s
}

func main() {
	flag.Parse()
	lis, err := net.Listen("tcp", fmt.Sprintf("0.0.0.0:%d", *port))
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	var opts []grpc.ServerOption
	grpcServer := grpc.NewServer(opts...)
	pb.RegisterDiscoveryServer(grpcServer, newServer())
	fmt.Printf("Discovery server running on %v\n", lis.Addr())
	grpcServer.Serve(lis)
}
