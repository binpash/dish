// Code generated by protoc-gen-go-grpc. DO NOT EDIT.
// versions:
// - protoc-gen-go-grpc v1.3.0
// - protoc             v5.26.1
// source: data_stream.proto

package proto

import (
	context "context"
	grpc "google.golang.org/grpc"
	codes "google.golang.org/grpc/codes"
	status "google.golang.org/grpc/status"
)

// This is a compile-time assertion to ensure that this generated file
// is compatible with the grpc package it is being compiled against.
// Requires gRPC-Go v1.32.0 or later.
const _ = grpc.SupportPackageIsVersion7

const (
	Discovery_PutAddr_FullMethodName                  = "/Discovery/PutAddr"
	Discovery_GetAddr_FullMethodName                  = "/Discovery/GetAddr"
	Discovery_RemoveAddr_FullMethodName               = "/Discovery/RemoveAddr"
	Discovery_ReadStream_FullMethodName               = "/Discovery/readStream"
	Discovery_WriteStream_FullMethodName              = "/Discovery/writeStream"
	Discovery_PutAddrOptimized_FullMethodName         = "/Discovery/PutAddrOptimized"
	Discovery_GetAddrOptimized_FullMethodName         = "/Discovery/GetAddrOptimized"
	Discovery_FindPersistedOptimized_FullMethodName   = "/Discovery/FindPersistedOptimized"
	Discovery_RemovePersistedOptimized_FullMethodName = "/Discovery/RemovePersistedOptimized"
)

// DiscoveryClient is the client API for Discovery service.
//
// For semantics around ctx use and closing/ending streaming RPCs, please refer to https://pkg.go.dev/google.golang.org/grpc/?tab=doc#ClientConn.NewStream.
type DiscoveryClient interface {
	PutAddr(ctx context.Context, in *PutAddrMsg, opts ...grpc.CallOption) (*Status, error)
	GetAddr(ctx context.Context, in *AddrReq, opts ...grpc.CallOption) (*GetAddrReply, error)
	RemoveAddr(ctx context.Context, in *AddrReq, opts ...grpc.CallOption) (*Status, error)
	ReadStream(ctx context.Context, in *AddrReq, opts ...grpc.CallOption) (Discovery_ReadStreamClient, error)
	WriteStream(ctx context.Context, opts ...grpc.CallOption) (Discovery_WriteStreamClient, error)
	PutAddrOptimized(ctx context.Context, in *PutAddrMsg, opts ...grpc.CallOption) (*Status, error)
	GetAddrOptimized(ctx context.Context, in *AddrReq, opts ...grpc.CallOption) (*GetAddrReply, error)
	FindPersistedOptimized(ctx context.Context, in *FPMessage, opts ...grpc.CallOption) (*FPMessageReply, error)
	RemovePersistedOptimized(ctx context.Context, in *RPMessage, opts ...grpc.CallOption) (*Status, error)
}

type discoveryClient struct {
	cc grpc.ClientConnInterface
}

func NewDiscoveryClient(cc grpc.ClientConnInterface) DiscoveryClient {
	return &discoveryClient{cc}
}

func (c *discoveryClient) PutAddr(ctx context.Context, in *PutAddrMsg, opts ...grpc.CallOption) (*Status, error) {
	out := new(Status)
	err := c.cc.Invoke(ctx, Discovery_PutAddr_FullMethodName, in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *discoveryClient) GetAddr(ctx context.Context, in *AddrReq, opts ...grpc.CallOption) (*GetAddrReply, error) {
	out := new(GetAddrReply)
	err := c.cc.Invoke(ctx, Discovery_GetAddr_FullMethodName, in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *discoveryClient) RemoveAddr(ctx context.Context, in *AddrReq, opts ...grpc.CallOption) (*Status, error) {
	out := new(Status)
	err := c.cc.Invoke(ctx, Discovery_RemoveAddr_FullMethodName, in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *discoveryClient) ReadStream(ctx context.Context, in *AddrReq, opts ...grpc.CallOption) (Discovery_ReadStreamClient, error) {
	stream, err := c.cc.NewStream(ctx, &Discovery_ServiceDesc.Streams[0], Discovery_ReadStream_FullMethodName, opts...)
	if err != nil {
		return nil, err
	}
	x := &discoveryReadStreamClient{stream}
	if err := x.ClientStream.SendMsg(in); err != nil {
		return nil, err
	}
	if err := x.ClientStream.CloseSend(); err != nil {
		return nil, err
	}
	return x, nil
}

type Discovery_ReadStreamClient interface {
	Recv() (*Data, error)
	grpc.ClientStream
}

type discoveryReadStreamClient struct {
	grpc.ClientStream
}

func (x *discoveryReadStreamClient) Recv() (*Data, error) {
	m := new(Data)
	if err := x.ClientStream.RecvMsg(m); err != nil {
		return nil, err
	}
	return m, nil
}

func (c *discoveryClient) WriteStream(ctx context.Context, opts ...grpc.CallOption) (Discovery_WriteStreamClient, error) {
	stream, err := c.cc.NewStream(ctx, &Discovery_ServiceDesc.Streams[1], Discovery_WriteStream_FullMethodName, opts...)
	if err != nil {
		return nil, err
	}
	x := &discoveryWriteStreamClient{stream}
	return x, nil
}

type Discovery_WriteStreamClient interface {
	Send(*Data) error
	CloseAndRecv() (*Status, error)
	grpc.ClientStream
}

type discoveryWriteStreamClient struct {
	grpc.ClientStream
}

func (x *discoveryWriteStreamClient) Send(m *Data) error {
	return x.ClientStream.SendMsg(m)
}

func (x *discoveryWriteStreamClient) CloseAndRecv() (*Status, error) {
	if err := x.ClientStream.CloseSend(); err != nil {
		return nil, err
	}
	m := new(Status)
	if err := x.ClientStream.RecvMsg(m); err != nil {
		return nil, err
	}
	return m, nil
}

func (c *discoveryClient) PutAddrOptimized(ctx context.Context, in *PutAddrMsg, opts ...grpc.CallOption) (*Status, error) {
	out := new(Status)
	err := c.cc.Invoke(ctx, Discovery_PutAddrOptimized_FullMethodName, in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *discoveryClient) GetAddrOptimized(ctx context.Context, in *AddrReq, opts ...grpc.CallOption) (*GetAddrReply, error) {
	out := new(GetAddrReply)
	err := c.cc.Invoke(ctx, Discovery_GetAddrOptimized_FullMethodName, in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *discoveryClient) FindPersistedOptimized(ctx context.Context, in *FPMessage, opts ...grpc.CallOption) (*FPMessageReply, error) {
	out := new(FPMessageReply)
	err := c.cc.Invoke(ctx, Discovery_FindPersistedOptimized_FullMethodName, in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *discoveryClient) RemovePersistedOptimized(ctx context.Context, in *RPMessage, opts ...grpc.CallOption) (*Status, error) {
	out := new(Status)
	err := c.cc.Invoke(ctx, Discovery_RemovePersistedOptimized_FullMethodName, in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

// DiscoveryServer is the server API for Discovery service.
// All implementations must embed UnimplementedDiscoveryServer
// for forward compatibility
type DiscoveryServer interface {
	PutAddr(context.Context, *PutAddrMsg) (*Status, error)
	GetAddr(context.Context, *AddrReq) (*GetAddrReply, error)
	RemoveAddr(context.Context, *AddrReq) (*Status, error)
	ReadStream(*AddrReq, Discovery_ReadStreamServer) error
	WriteStream(Discovery_WriteStreamServer) error
	PutAddrOptimized(context.Context, *PutAddrMsg) (*Status, error)
	GetAddrOptimized(context.Context, *AddrReq) (*GetAddrReply, error)
	FindPersistedOptimized(context.Context, *FPMessage) (*FPMessageReply, error)
	RemovePersistedOptimized(context.Context, *RPMessage) (*Status, error)
	mustEmbedUnimplementedDiscoveryServer()
}

// UnimplementedDiscoveryServer must be embedded to have forward compatible implementations.
type UnimplementedDiscoveryServer struct {
}

func (UnimplementedDiscoveryServer) PutAddr(context.Context, *PutAddrMsg) (*Status, error) {
	return nil, status.Errorf(codes.Unimplemented, "method PutAddr not implemented")
}
func (UnimplementedDiscoveryServer) GetAddr(context.Context, *AddrReq) (*GetAddrReply, error) {
	return nil, status.Errorf(codes.Unimplemented, "method GetAddr not implemented")
}
func (UnimplementedDiscoveryServer) RemoveAddr(context.Context, *AddrReq) (*Status, error) {
	return nil, status.Errorf(codes.Unimplemented, "method RemoveAddr not implemented")
}
func (UnimplementedDiscoveryServer) ReadStream(*AddrReq, Discovery_ReadStreamServer) error {
	return status.Errorf(codes.Unimplemented, "method ReadStream not implemented")
}
func (UnimplementedDiscoveryServer) WriteStream(Discovery_WriteStreamServer) error {
	return status.Errorf(codes.Unimplemented, "method WriteStream not implemented")
}
func (UnimplementedDiscoveryServer) PutAddrOptimized(context.Context, *PutAddrMsg) (*Status, error) {
	return nil, status.Errorf(codes.Unimplemented, "method PutAddrOptimized not implemented")
}
func (UnimplementedDiscoveryServer) GetAddrOptimized(context.Context, *AddrReq) (*GetAddrReply, error) {
	return nil, status.Errorf(codes.Unimplemented, "method GetAddrOptimized not implemented")
}
func (UnimplementedDiscoveryServer) FindPersistedOptimized(context.Context, *FPMessage) (*FPMessageReply, error) {
	return nil, status.Errorf(codes.Unimplemented, "method FindPersistedOptimized not implemented")
}
func (UnimplementedDiscoveryServer) RemovePersistedOptimized(context.Context, *RPMessage) (*Status, error) {
	return nil, status.Errorf(codes.Unimplemented, "method RemovePersistedOptimized not implemented")
}
func (UnimplementedDiscoveryServer) mustEmbedUnimplementedDiscoveryServer() {}

// UnsafeDiscoveryServer may be embedded to opt out of forward compatibility for this service.
// Use of this interface is not recommended, as added methods to DiscoveryServer will
// result in compilation errors.
type UnsafeDiscoveryServer interface {
	mustEmbedUnimplementedDiscoveryServer()
}

func RegisterDiscoveryServer(s grpc.ServiceRegistrar, srv DiscoveryServer) {
	s.RegisterService(&Discovery_ServiceDesc, srv)
}

func _Discovery_PutAddr_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(PutAddrMsg)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(DiscoveryServer).PutAddr(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: Discovery_PutAddr_FullMethodName,
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(DiscoveryServer).PutAddr(ctx, req.(*PutAddrMsg))
	}
	return interceptor(ctx, in, info, handler)
}

func _Discovery_GetAddr_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(AddrReq)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(DiscoveryServer).GetAddr(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: Discovery_GetAddr_FullMethodName,
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(DiscoveryServer).GetAddr(ctx, req.(*AddrReq))
	}
	return interceptor(ctx, in, info, handler)
}

func _Discovery_RemoveAddr_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(AddrReq)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(DiscoveryServer).RemoveAddr(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: Discovery_RemoveAddr_FullMethodName,
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(DiscoveryServer).RemoveAddr(ctx, req.(*AddrReq))
	}
	return interceptor(ctx, in, info, handler)
}

func _Discovery_ReadStream_Handler(srv interface{}, stream grpc.ServerStream) error {
	m := new(AddrReq)
	if err := stream.RecvMsg(m); err != nil {
		return err
	}
	return srv.(DiscoveryServer).ReadStream(m, &discoveryReadStreamServer{stream})
}

type Discovery_ReadStreamServer interface {
	Send(*Data) error
	grpc.ServerStream
}

type discoveryReadStreamServer struct {
	grpc.ServerStream
}

func (x *discoveryReadStreamServer) Send(m *Data) error {
	return x.ServerStream.SendMsg(m)
}

func _Discovery_WriteStream_Handler(srv interface{}, stream grpc.ServerStream) error {
	return srv.(DiscoveryServer).WriteStream(&discoveryWriteStreamServer{stream})
}

type Discovery_WriteStreamServer interface {
	SendAndClose(*Status) error
	Recv() (*Data, error)
	grpc.ServerStream
}

type discoveryWriteStreamServer struct {
	grpc.ServerStream
}

func (x *discoveryWriteStreamServer) SendAndClose(m *Status) error {
	return x.ServerStream.SendMsg(m)
}

func (x *discoveryWriteStreamServer) Recv() (*Data, error) {
	m := new(Data)
	if err := x.ServerStream.RecvMsg(m); err != nil {
		return nil, err
	}
	return m, nil
}

func _Discovery_PutAddrOptimized_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(PutAddrMsg)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(DiscoveryServer).PutAddrOptimized(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: Discovery_PutAddrOptimized_FullMethodName,
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(DiscoveryServer).PutAddrOptimized(ctx, req.(*PutAddrMsg))
	}
	return interceptor(ctx, in, info, handler)
}

func _Discovery_GetAddrOptimized_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(AddrReq)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(DiscoveryServer).GetAddrOptimized(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: Discovery_GetAddrOptimized_FullMethodName,
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(DiscoveryServer).GetAddrOptimized(ctx, req.(*AddrReq))
	}
	return interceptor(ctx, in, info, handler)
}

func _Discovery_FindPersistedOptimized_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(FPMessage)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(DiscoveryServer).FindPersistedOptimized(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: Discovery_FindPersistedOptimized_FullMethodName,
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(DiscoveryServer).FindPersistedOptimized(ctx, req.(*FPMessage))
	}
	return interceptor(ctx, in, info, handler)
}

func _Discovery_RemovePersistedOptimized_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(RPMessage)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(DiscoveryServer).RemovePersistedOptimized(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: Discovery_RemovePersistedOptimized_FullMethodName,
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(DiscoveryServer).RemovePersistedOptimized(ctx, req.(*RPMessage))
	}
	return interceptor(ctx, in, info, handler)
}

// Discovery_ServiceDesc is the grpc.ServiceDesc for Discovery service.
// It's only intended for direct use with grpc.RegisterService,
// and not to be introspected or modified (even as a copy)
var Discovery_ServiceDesc = grpc.ServiceDesc{
	ServiceName: "Discovery",
	HandlerType: (*DiscoveryServer)(nil),
	Methods: []grpc.MethodDesc{
		{
			MethodName: "PutAddr",
			Handler:    _Discovery_PutAddr_Handler,
		},
		{
			MethodName: "GetAddr",
			Handler:    _Discovery_GetAddr_Handler,
		},
		{
			MethodName: "RemoveAddr",
			Handler:    _Discovery_RemoveAddr_Handler,
		},
		{
			MethodName: "PutAddrOptimized",
			Handler:    _Discovery_PutAddrOptimized_Handler,
		},
		{
			MethodName: "GetAddrOptimized",
			Handler:    _Discovery_GetAddrOptimized_Handler,
		},
		{
			MethodName: "FindPersistedOptimized",
			Handler:    _Discovery_FindPersistedOptimized_Handler,
		},
		{
			MethodName: "RemovePersistedOptimized",
			Handler:    _Discovery_RemovePersistedOptimized_Handler,
		},
	},
	Streams: []grpc.StreamDesc{
		{
			StreamName:    "readStream",
			Handler:       _Discovery_ReadStream_Handler,
			ServerStreams: true,
		},
		{
			StreamName:    "writeStream",
			Handler:       _Discovery_WriteStream_Handler,
			ClientStreams: true,
		},
	},
	Metadata: "data_stream.proto",
}
