#include <atomic>
#include <csignal>

#include "grpcpp/grpcpp.h"
#include "current/bricks/dflags/dflags.h"
#include "current/bricks/sync/waitable_atomic.h"
#include "current/blocks/xterm/vt100.h"
#include "current/blocks/http/api.h"
#include "schema.grpc.pb.h"

DEFINE_uint16(port, 5555, "The port to use.");
DEFINE_uint16(http_server, 0, "The port to HTTP-listen on, for the readiness signal.");

using namespace current::vt100;

void HandleSignal(int code) {
  std::cerr << "\nReceived signal " << code << ", terminating.\n";
  std::exit(code);
}

int main(int argc, char** argv) {
  signal(SIGINT, HandleSignal);

#ifndef NDEBUG
  std::cout << bold << yellow << "WARNING" << reset << ": running a " << bold << red << "DEBUG" << reset
            << " build. Suboptimal for performance testing." << std::endl;
#endif

  ParseDFlags(&argc, &argv);

  struct StreamServiceImpl final : test_bidi_stream::RPCBidiStream::Service {
    std::atomic_uint64_t number_of_requests = std::atomic_uint64_t(0ull);
    grpc::Status Go(grpc::ServerContext*,
                    grpc::ServerReaderWriter<test_bidi_stream::Res, test_bidi_stream::Req>* stream) override {
      std::cerr << "Created a stream." << std::endl;

      test_bidi_stream::Req req;
      test_bidi_stream::Res res;
      auto wo = grpc::WriteOptions().set_buffer_hint();

      while (stream->Read(&req)) {
        ++number_of_requests;

        std::string s = req.s();
        int32_t i = req.i();
        int32_t c = req.c();
        int32_t n = req.n();

        if (i < 0) {
          i = 0;
        }
        if (i > static_cast<int32_t>(s.length())) {
          i = static_cast<int32_t>(s.length());
        }

        s = s.substr(i, c);

        res.set_id(req.id());
        if (n <= 1) {
          res.set_r(s);
        } else {
          std::ostringstream os;
          for (int32_t t = 0; t < n; ++t) {
            os << s;
          }
          res.set_r(os.str());
        }
        stream->Write(res, wo);
      }

      std::cerr << "Closing a stream." << std::endl;
      return grpc::Status::OK;
    }
  };

  StreamServiceImpl service;

  grpc::ServerBuilder builder;
  builder.AddListeningPort("0.0.0.0:" + std::to_string(FLAGS_port), grpc::InsecureServerCredentials());
  builder.RegisterService(&service);
  std::unique_ptr<grpc::Server> server(builder.BuildAndStart());
  if (!FLAGS_http_server) {
    std::cout << "The gRPC service is up on port " << FLAGS_port << ", Ctrl+C to stop." << std::endl;
    server->Wait();
  } else {
    std::cout << "The gRPC service is up on port " << FLAGS_port << '.' << std::endl;
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
      kill_switch.MutableUse([](bool& flag) { flag = true; });
    });
    std::cout << "The HTTP service is up on port " << FLAGS_http_server << ", /kill to stop." << std::endl;
    kill_switch.Wait([](bool flag) { return flag; });
  }
}
