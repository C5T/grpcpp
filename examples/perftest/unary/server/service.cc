#include <atomic>
#include <csignal>

#include "current/blocks/http/api.h"
#include "current/bricks/dflags/dflags.h"
#include "current/bricks/sync/waitable_atomic.h"
#include "grpcpp/grpcpp.h"
#include "schema.grpc.pb.h"

DEFINE_uint16(server, 5555, "The port to listen on.");
DEFINE_uint16(http_server, 0, "The port to HTTP-listen on, for the readiness signal.");

struct ServiceImpl final : sync_service::RPC::Service {
  std::atomic_size_t number_of_requests = std::atomic_size_t(0u);
  grpc::Status SyncCall(grpc::ServerContext* context, sync_service::Req const* req, sync_service::Res* res) override {
    ++number_of_requests;
    int64_t const result = req->a() + req->b();
    // Fail each 3rd request, hehe.
    res->set_c((result % 3 == 0) ? result + 1 : result);
    return grpc::Status::OK;
  }
};

void HandleSignal(int code) {
  std::cerr << "\nReceived signal " << code << ", terminating.\n";
  std::exit(code);
}

int main(int argc, char** argv) {
  signal(SIGINT, HandleSignal);

  ParseDFlags(&argc, &argv);

#ifndef NDEBUG
  std::cout << "Running a DEBUG build!" << std::endl;
#endif

  std::cout << "Starting `sync_service` on gRPC port " << FLAGS_server << std::endl;

  ServiceImpl service;

  grpc::ServerBuilder builder;
  builder.AddListeningPort("0.0.0.0:" + std::to_string(FLAGS_server), grpc::InsecureServerCredentials());
  builder.RegisterService(&service);

  std::unique_ptr<grpc::Server> server(builder.BuildAndStart());

  if (!FLAGS_http_server) {
    std::cout << "The gRPC service is up on port " << FLAGS_server << ", Ctrl+C to stop." << std::endl;
    server->Wait();
  } else {
    std::cout << "The gRPC service is up on port " << FLAGS_server << '.' << std::endl;
    current::WaitableAtomic<bool> kill_switch(false);
    auto& http = HTTP(current::net::BarePort(FLAGS_http_server));
    HTTPRoutesScope routes;
    routes += http.Register("/", [](Request r) {
      r("OK\n");
    });
    routes += http.Register("/stats", [&](Request r) {
      r("Requests: " + current::ToString(static_cast<uint32_t>(service.number_of_requests)) + '\n');
    });
    routes += http.Register("/kill", [&](Request r) {
      r("Terminating.\n");
      kill_switch.MutableUse([](bool& flag) {
        flag = true;
      });
    });
    std::cout << "The HTTP service is up on port " << FLAGS_http_server << ", /kill to stop." << std::endl;
    kill_switch.Wait([](bool flag) {
      return flag;
    });
  }
}
