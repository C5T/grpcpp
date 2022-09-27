#!/bin/bash
#
# Usage from Linux: `alias grpcpp=/path/to/grpcpp.sh`.

SRC=$1
if [ ! -d "$SRC" ] ; then
  echo 'The first command line argument should be the name of the directory, under $PWD, to run `grpcpp` on.'
  exit 1
fi
BUILD="$PWD/.build_$SRC"
mkdir -p "$BUILD"
shift
docker run --network host -u $(id -u):$(id -g) -v $PWD/$SRC:/src -v "$BUILD":/build -it crnt/grpcpp $*
