cmake_minimum_required(VERSION 3.14.1)

project(grpc_playground C CXX)

set(CMAKE_CXX_STANDARD 17)
find_package(Threads REQUIRED)

set(current_SOURCE_DIR "${CMAKE_SOURCE_DIR}/../current")

set(protobuf_MODULE_COMPATIBLE TRUE)
find_package(Protobuf CONFIG REQUIRED)
message(STATUS "Using protobuf ${Protobuf_VERSION}")

find_package(gRPC CONFIG REQUIRED)
message(STATUS "Using gRPC ${gRPC_VERSION}")

message(STATUS "CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}")

set(GRPCPP gRPC::grpc++)
set(GRPC_CPP_PLUGIN_EXECUTABLE $<TARGET_FILE:gRPC::grpc_cpp_plugin>)
set(LIBPROTOBUF protobuf::libprotobuf)
set(GRPCPP_REFLECTION gRPC::grpc++_reflection)
set(PROTOC $<TARGET_FILE:protobuf::protoc>)

set(GRPC_PROTO_DEPS "")

file(GLOB_RECURSE PROTO_FILES "/all_srcs/*.proto")
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
target_link_libraries(schema_deps PRIVATE ${GRPCPP} ${GRPCPP_REFLECTION} ${LIBPROTOBUF})
include_directories("${CMAKE_CURRENT_BINARY_DIR}")

# TODO(dkorolev): Why copy files at all, if I could `GLOB` them from where they are?

set(OBJECTS_LIST "")
file(GLOB_RECURSE SOURCE_FILES "/all_srcs/src/*.cc" "/extra/*.cc")
foreach(SOURCE_FILE ${SOURCE_FILES})
  get_filename_component(TARGET_NAME "${SOURCE_FILE}" NAME_WE)
  add_library("${TARGET_NAME}.o" OBJECT "${SOURCE_FILE}")

  target_link_libraries(${TARGET_NAME}.o schema_deps ${GRPCPP} ${GRPCPP_REFLECTION})
  target_include_directories(${TARGET_NAME}.o PUBLIC "${current_SOURCE_DIR}/.." "${CMAKE_CURRENT_BINARY_DIR}" "/grpc_installed/include" "/grpcpp_lib" "/all_srcs/src" "/extra")

  list(APPEND OBJECTS_LIST "${TARGET_NAME}.o")
endforeach()

add_executable("___binary___" "/all_srcs/___dummy___.cc")
target_link_libraries("___binary___" ${OBJECTS_LIST})
