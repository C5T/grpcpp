#!/bin/bash
#
# Usage from Linux: `alias grpcpp=/path/to/grpcpp.sh`.

SRC=$1
BUILD="$PWD/.build_$SRC"
mkdir -p "$BUILD"
shift
docker run -u $(id -u):$(id -g) -v $PWD/$SRC:/src -v "$BUILD":/build -it crnt/grpcpp $*
