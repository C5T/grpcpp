#include "grpcpp/grpcpp.h"
#include "current/bricks/dflags/dflags.h"
#include "schema.grpc.pb.h"

DEFINE_uint16(server, 5555, "The port to listen on.");

struct ServiceImpl final : sync_service::RPC::Service {
  grpc::Status SyncCall(grpc::ServerContext* context, sync_service::Req const* req, sync_service::Res* res) override {
    int64_t const result = req->a() + req->b();
    // Fail each 3rd request, hehe.
    res->set_c((result % 3 == 0) ? result + 1 : result);
    return grpc::Status::OK;
  }
};

int main(int argc, char** argv) {
  ParseDFlags(&argc, &argv);

  std::cout << "Starting `sync_service` on port " << FLAGS_server << std::endl;

  ServiceImpl service;

  grpc::ServerBuilder builder;
  builder.AddListeningPort("0.0.0.0:" + std::to_string(FLAGS_server), grpc::InsecureServerCredentials());
  builder.RegisterService(&service);

  std::unique_ptr<grpc::Server> server(builder.BuildAndStart());

  std::cout << "The service is up. Ctrl+C to cancel." << std::endl;
  server->Wait();
}
