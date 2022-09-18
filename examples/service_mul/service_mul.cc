#include <thread>

#include "grpcpp/grpcpp.h"
#include "current/bricks/dflags/dflags.h"
#include "service_mul.grpc.pb.h"

DEFINE_uint16(server, 0, "If set, starts the service on this port, ex. `--server 5001`.");
DEFINE_string(client, "", "If set, connects to the service running on this port, ex. `--client 172.17.0.1:5001`.");
DEFINE_int32(a, 3, "A number to multiply.");
DEFINE_int32(b, 5, "Another number to multiply.");

struct ServiceMulImpl final : service_multiply::RPC::Service {
  grpc::Status Multiply(grpc::ServerContext* context, service_multiply::Req const* req, service_multiply::Res* res) override {
    res->set_c(req->a() * req->b());
    return grpc::Status::OK;
  }
};

int main(int argc, char** argv) {
  ParseDFlags(&argc, &argv);

  if (FLAGS_server) {
    std::cout
        << "Starting `service_multiply` on port " << FLAGS_server
        << ". Don't forget to expose it from Docker." << std::endl;

    ServiceMulImpl service;

    grpc::ServerBuilder builder;
    builder.AddListeningPort("0.0.0.0:" + std::to_string(FLAGS_server), grpc::InsecureServerCredentials());
    builder.RegisterService(&service);

    std::unique_ptr<grpc::Server> server(builder.BuildAndStart());

    std::cout << "The service is up. Ctrl+C to cancel." << std::endl;
    server->Wait();
  } else if (!FLAGS_client.empty()) {
    std::cout
        << "Connecting to `" << FLAGS_client << "` to multiply "
        << FLAGS_a << " by " << FLAGS_b << '.' << std::endl;

    std::shared_ptr<grpc::Channel> channel = grpc::CreateChannel(FLAGS_client, grpc::InsecureChannelCredentials());
    std::cout << "Channel created." << std::endl;

    std::unique_ptr<service_multiply::RPC::Stub> stub(service_multiply::RPC::NewStub(channel));
    std::cout << "Stub created." << std::endl;

    service_multiply::Req req;
    req.set_a(FLAGS_a);
    req.set_b(FLAGS_b);

    service_multiply::Res res;

    grpc::ClientContext context;
    grpc::Status const status = stub->Multiply(&context, req, &res);

    if (status.ok()) {
      std::cout << "Result: " << res.c() << '.' << std::endl;
    } else {
      std::cout << "Result: status not OK." << std::endl;
    }
  } else {
    std::cout << "Please set entier `--server` or `--client`." << std::endl;
    return -1;
  }
}
