#!/bin/bash
#
# Usage from Linux: `alias grpcpp=/path/to/grpcpp.sh`.

DEFAULT_DOCKER_CONTAINER=crnt/grpcpp
DOCKER_CONTAINER=${GRPCPP_CONTAINER:-$DEFAULT_DOCKER_CONTAINER}

DOCKER_RUN_PARAMS=""
if [ "$GRPCPP_MODE" == "daemon" ] ; then
  DOCKER_RUN_PARAMS=-d
else
  DOCKER_RUN_PARAMS=-it
fi

if [ "$DOCKER_CONTAINER" != "$DEFAULT_DOCKER_CONTAINER" ] ; then
  echo -e '\033[1m\033[36m=== CUSTOM CONTAINER ===\033[0m'
  echo
  echo 'Using GRPCPP_CONTAINER='$DOCKER_CONTAINER
  echo
fi

SRC="$1"
if [ ! -d "$SRC" ] ; then
  echo 'The first command line argument should be the name of the directory, under $PWD, to run `grpcpp` on.'
  exit 1
fi
BUILD="$PWD/.build_$SRC"
mkdir -p "$BUILD"
shift

docker run --network host -u $(id -u):$(id -g) -v "$PWD/$SRC":/src -v "$BUILD":/build $DOCKER_RUN_PARAMS $DOCKER_CONTAINER $*
