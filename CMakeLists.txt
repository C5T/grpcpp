cmake_minimum_required(VERSION 3.14.1)

project(grpc_playground C CXX)

set(CMAKE_CXX_STANDARD 17)
find_package(Threads REQUIRED)

set(current_SOURCE_DIR "${CMAKE_SOURCE_DIR}/../current")
include_directories("${current_SOURCE_DIR}/..")

set(protobuf_MODULE_COMPATIBLE TRUE)
find_package(Protobuf CONFIG REQUIRED)
message(STATUS "Using protobuf ${Protobuf_VERSION}")

find_package(gRPC CONFIG REQUIRED)
message(STATUS "Using gRPC ${gRPC_VERSION}")

set(GRPCPP gRPC::grpc++)
set(GRPC_CPP_PLUGIN_EXECUTABLE $<TARGET_FILE:gRPC::grpc_cpp_plugin>)
set(LIBPROTOBUF protobuf::libprotobuf)
set(GRPCPP_REFLECTION gRPC::grpc++_reflection)
set(PROTOC $<TARGET_FILE:protobuf::protoc>)

set(GRPC_PROTO_DEPS "")

file(GLOB_RECURSE PROTO_FILES "src/*.proto")
foreach(PROTO_FILE ${PROTO_FILES})
  get_filename_component(PROTO_NAME "${PROTO_FILE}" NAME_WE)
  get_filename_component(PROTO_PATH "${PROTO_FILE}" PATH)

  set(PROTO_SRCS "${CMAKE_CURRENT_BINARY_DIR}/${PROTO_NAME}.pb.cc")
  set(PROTO_HDRS "${CMAKE_CURRENT_BINARY_DIR}/${PROTO_NAME}.pb.h")
  set(GRPC_SRCS "${CMAKE_CURRENT_BINARY_DIR}/${PROTO_NAME}.grpc.pb.cc")
  set(GRPC_HDRS "${CMAKE_CURRENT_BINARY_DIR}/${PROTO_NAME}.grpc.pb.h")

  add_custom_command(OUTPUT "${PROTO_SRCS}" "${PROTO_HDRS}" "${GRPC_SRCS}" "${GRPC_HDRS}"
                     COMMAND ${PROTOC}
                     ARGS --grpc_out "${CMAKE_CURRENT_BINARY_DIR}"
                          --cpp_out "${CMAKE_CURRENT_BINARY_DIR}"
                          --plugin=protoc-gen-grpc="${GRPC_CPP_PLUGIN_EXECUTABLE}"
                          -I "${PROTO_PATH}"
                          "${PROTO_FILE}"
                     DEPENDS "${PROTO_FILE}")

  set(GRPC_PROTO_DEPS ${GRPC_PROTO_DEPS} ${GRPC_SRCS} ${GRPC_HDRS} ${PROTO_SRCS} ${PROTO_HDRS})
endforeach()

add_library(schema_deps ${GRPC_PROTO_DEPS})
include_directories("${CMAKE_CURRENT_BINARY_DIR}")

include_directories("/grpcpp_lib")

target_link_libraries(schema_deps ${GRPCPP} ${GRPCPP_REFLECTION} ${LIBPROTOBUF})

file(GLOB_RECURSE SOURCE_FILES "src/*.cc")
foreach(SOURCE_FILE ${SOURCE_FILES})
  get_filename_component(TARGET_NAME "${SOURCE_FILE}" NAME_WE)
  add_executable(${TARGET_NAME} "${SOURCE_FILE}")
  target_link_libraries(${TARGET_NAME} schema_deps ${GRPCPP} ${GRPCPP_REFLECTION} ${LIBPROTOBUF})
endforeach()
