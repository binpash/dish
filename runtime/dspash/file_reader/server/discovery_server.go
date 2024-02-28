package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"log"
	"net"
	"sync"
	"time"

	"google.golang.org/grpc"

	pb "dspash/datastream"
)

var (
	port          = flag.Int("port", 50052, "The server port")
	chunkSize     = flag.Int("chunk_size", 4*1024, "The chunk size for the rpc stream")
	streamTimeout = flag.Int("t", 10, "Wait period in seconds before we give up")
)

type DiscoveryServer struct {
	pb.UnimplementedDiscoveryServer
	addrs                        map[string]string
	streams                      map[string]chan []byte
	mu                           sync.Mutex // protects addrs
	writerDiscoveryServerAddrs   map[string]string
	muWriterDiscoveryServerAddrs sync.Mutex // protect writerDiscoveryServerAddrs
}

func (s *DiscoveryServer) PutAddr(ctx context.Context, msg *pb.PutAddrMsg) (*pb.Status, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	addr, id := msg.Addr, msg.Id
	if _, ok := s.addrs[id]; ok {
		return &pb.Status{Success: false}, errors.New("PutAddr: id already inserted\n")
	}

	s.addrs[id] = addr
	log.Printf("Discovery server PutAddr mapping id %s to addr %s\n", id, addr)
	return &pb.Status{Success: true}, nil
}

func (s *DiscoveryServer) GetAddr(ctx context.Context, msg *pb.AddrReq) (*pb.GetAddrReply, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	log.Printf("Received a request to get addr for id%v\n", msg.Id)
	addr, ok := s.addrs[msg.Id]
	log.Printf("s.addrs: %v\n", s.addrs)
	if !ok {
		return &pb.GetAddrReply{Success: false}, errors.New("GetAddr: id not found, retry in a little bit\n")
	}

	return &pb.GetAddrReply{Success: true, Addr: addr}, nil
}

func (s *DiscoveryServer) RemoveAddr(ctx context.Context, msg *pb.AddrReq) (*pb.Status, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	_, ok := s.addrs[msg.Id]
	if !ok {
		return &pb.Status{Success: false}, errors.New("RemoveAddr: id not found\n")
	}

	delete(s.addrs, msg.Id)
	return &pb.Status{Success: true}, nil
}

// Note: this isn't exactly to update writer's addr - we don't even have the writer's exact addr yet
//		this is to update the peer discovery_server's addr for rfifo port so that we can ask this new discovery_server addr
//		what the writer's addr is exactly.
func (s *DiscoveryServer) UpdateWriterServerAddr(ctx context.Context, msg *pb.UpdateWriterServerAddrReq) (*pb.Status, error) {
	s.muWriterDiscoveryServerAddrs.Lock()
	defer s.muWriterDiscoveryServerAddrs.Unlock()

	// TODO: msg.OldAddr isn't really used
	if s.writerDiscoveryServerAddrs == nil {
		s.writerDiscoveryServerAddrs = make(map[string]string)
	}
	log.Printf("%v\n", msg)
	id, newAddr := msg.Id, msg.NewAddr
	s.writerDiscoveryServerAddrs[id] = newAddr
	log.Printf("Update complete. To get writer addr for id %s, ask discovery_server at addr %s\n", id, newAddr)
	return &pb.Status{Success: true}, nil

	// TODO: when can we remove this mapping from s.writerDiscoveryServerAddrs like removeWriterAddr()?
}

func (s *DiscoveryServer) GetLatestWriterServerAddr(ctx context.Context, msg *pb.GetLatestWriterServerAddrReq) (*pb.GetAddrReply, error) {
	s.muWriterDiscoveryServerAddrs.Lock()
	defer s.muWriterDiscoveryServerAddrs.Unlock()

	id, writerServerAddr := msg.Id, msg.WriterServerAddr
	addr, ok := s.writerDiscoveryServerAddrs[id]
	if !ok {
		// Current writer server addr is still up-to-date
		return &pb.GetAddrReply{Success: true, Addr: writerServerAddr}, nil
	}
	return &pb.GetAddrReply{Success: true, Addr: addr}, nil
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
			return errors.New("No writer subscribed in timeout period")
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
	s.streams = map[string]chan []byte{}
	s.mu = sync.Mutex{}
	return s
}

func main() {
	flag.Parse()
	lis, err := net.Listen("tcp", fmt.Sprintf("0.0.0.0:%d", *port))
	log.SetFlags(log.Flags() | log.Lmsgprefix)
	log.SetPrefix(fmt.Sprintf("discovery server "))

	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	var opts []grpc.ServerOption
	grpcServer := grpc.NewServer(opts...)
	pb.RegisterDiscoveryServer(grpcServer, newServer())

	log.Printf("Hello from discovery server")
	fmt.Printf("Discovery server running on %v\n", lis.Addr())
	grpcServer.Serve(lis)
}
