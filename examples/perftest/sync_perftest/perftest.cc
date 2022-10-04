#include "current/utils/grpc_perftest_main.h"
#include "schema.grpc.pb.h"

DEFINE_string(grpc_server, "localhost:5555", "The server to perftest.");
DEFINE_uint64(queries_to_generate, 1'000'000, "The number of mock queries to generate.");

struct TestRunner final {
  using GRPCRequest = sync_service::Req;
  using GRPCResponse = sync_service::Res;
  using GRPCService = sync_service::RPC;
  using GoldenResponse = int64_t;

  template <typename F>
  static void GenerateData(F&& f) {
    for (uint64_t i = 0u; i < FLAGS_queries_to_generate; ++i) {
      GRPCRequest req;
      int64_t const a = rand() % 1'000'000;
      int64_t const b = rand() % 1'000'000;
      req.set_a(a);
      req.set_b(b);
      f(req, a + b);
    }
  }

  static bool Validate(GRPCResponse const& response, int64_t golden) {
    return response.c() == golden;
  }

  static grpc::Status Run(typename GRPCService::Stub& stub,
                          grpc::ClientContext* ctx,
                          GRPCRequest const& req,
                          GRPCResponse* res) {
    return stub.SyncCall(ctx, req, res);
  }
};
