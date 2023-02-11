FROM ubuntu:latest

RUN apt-get update
RUN apt-get install -y build-essential git cmake ninja-build gnuplot graphviz

# Get gRPC.
RUN git clone --depth 1 --recursive --shallow-submodules -b v1.47.3 https://github.com/grpc/grpc.git grpc_src

# Build Debug gRPC.
RUN mkdir /grpc_build_debug
RUN (cd /grpc_build_debug; cmake -DgRPC_INSTALL=ON -DgRPC_BUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=/grpc_installed_debug -DCMAKE_BUILD_TYPE=Debug /grpc_src)

RUN (cd /grpc_build_debug; make)
RUN (cd /grpc_build_debug; make install)

# Build Release gRPC.
RUN mkdir /grpc_build_release
RUN (cd /grpc_build_release; cmake -DgRPC_INSTALL=ON -DgRPC_BUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=/grpc_installed_release -DCMAKE_BUILD_TYPE=Release /grpc_src)

RUN (cd /grpc_build_release; make)
RUN (cd /grpc_build_release; make install)

# Make `current` available.
RUN git clone --depth 1 -b stable_2023_02_11 https://github.com/c5t/current

# TODO(dkorolev): Clean up these hacky scripts.
COPY CMakeLists.txt /
COPY entrypoint.sh /
COPY lib/grpc_perftest.h /current/utils/
COPY lib/grpc_perftest_main.h /current/utils/

RUN mkdir /all_srcs
RUN chmod a+rwx /all_srcs

ENTRYPOINT ["/entrypoint.sh"]
