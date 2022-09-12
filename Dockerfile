FROM ubuntu:latest

RUN apt-get update
RUN apt-get install -y build-essential git cmake ninja-build

# Install `grpc` into this system, as per https://grpc.io/docs/languages/cpp/quickstart/
RUN git clone --depth 1 --recursive --shallow-submodules -b v1.48.1 https://github.com/grpc/grpc.git grpc_src
RUN mkdir /grpc_build
RUN (cd /grpc_build; cmake -DgRPC_INSTALL=ON -DgRPC_BUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=/grpc_installed -DCMAKE_BUILD_TYPE=Release /grpc_src)
RUN (cd /grpc_build; make)
RUN (cd /grpc_build; make install)
ENV GRPC_INSTALL_DIR=/grpc_installed

# Make `current` available.
RUN git clone --depth 1 -b stable_2022_04_10 https://github.com/c5t/current

# And make use of the hacky scripts that seem to do the job.
COPY CMakeLists.txt /
COPY Makefile /
COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
