#!/bin/bash
#
# Usage from Linux: `alias grpcpp=/path/to/grpcpp.sh`.

if [ "$CMAKE_BUILD_TYPE" == "" ] || [ "$CMAKE_BUILD_TYPE" == "Release" ] ; then
  TARGET="release"
elif [ "$CMAKE_BUILD_TYPE" == "Debug" ] ; then
  TARGET="debug"
else
  echo '"$CMAKE_BUILD_TYPE" should be unset, `Debug` or `Release`.'
  exit 1
fi

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

mkdir -p "$PWD/.build_${TARGET}_${SRC}"
shift

MOUNT_VOLUMES_FLAGS='-v "'$PWD'/.build_'$TARGET'_'$SRC'":/build_'$TARGET' -v "'$PWD'/'$SRC'":/src'

while [ "$1" != "--" ] && [ -d "$1" ] ; do
  MOUNT_VOLUMES_FLAGS="$MOUNT_VOLUMES_FLAGS -v \"$PWD/$1\":\"/extra/$(basename "$1")\""
  shift
done

if [ "$1" == "--" ] ; then
  shift
fi

# TODO(dkorolev): There is no `--network host` on a Mac, fix the command.
cat <<EOF >"$PWD/.build_${TARGET}_${SRC}"/go.sh
  docker run \
    -e GRPCPP_ONLY_BUILD \
    -e CMAKE_BUILD_TYPE \
    -e GRPC_TRACE \
    -e GRPC_VERBOSITY \
    --network host \
    -u $(id -u):$(id -g) $MOUNT_VOLUMES_FLAGS $DOCKER_RUN_PARAMS $DOCKER_CONTAINER $*
EOF

chmod +x "$PWD/.build_${TARGET}_${SRC}"/go.sh
"$PWD/.build_${TARGET}_${SRC}"/go.sh
