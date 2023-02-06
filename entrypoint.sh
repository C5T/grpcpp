#!/bin/bash

SRC_COUNT=$(find /src -iname "*.cc" 2>/dev/null | wc -l)

if [ "$SRC_COUNT" == "0" ] ; then
  echo -e '\033[1m\033[36m=== USAGE ===\033[0m'
  echo
  echo 'TL;DR: Check out the README on https://github.com/c5t/grpcpp.'
  echo
  echo 'To use this container manually, Mount a directory under which there exists a `.cc` file as `/src`.'
  echo 'This directory may also contain or more `.proto` files.'
  echo
  echo 'The source file will be built, along with all the proto files.'
  echo 'The resulting binary will then be run.'
  echo 'The command line arguments will be passed along to this binary.'
  echo
  echo 'Do not forget to mount the necessary folders with data files, and to open the necessary ports.'
  echo 'Running with `--network host` is probably a good idea.'
  echo
  echo 'You may also mount some directory as `/build`. This will have two benefits:'
  echo '1) Rebuilds will be incremental, and, thus, faster.'
  echo '2) If your host system is Ubuntu, you would be able to run the built binaries.'
  exit 0
fi

# TODO(dkorolev): Why copy?
cp -r -p /src /all_srcs
cp -r -p /extra /all_srcs/___extra___ 2>/dev/null

if [ "$CMAKE_BUILD_TYPE" == "" ] || [ "$CMAKE_BUILD_TYPE" == "Release" ] ; then
  MAKE_TARGET="release"
  MAKE_TARGET_CAMEL_CASE="Release"
  GRPC_INSTALL_DIR=/grpc_installed_release
elif [ "$CMAKE_BUILD_TYPE" == "Debug" ] ; then
  MAKE_TARGET="debug"
  MAKE_TARGET_CAMEL_CASE="Debug"
  GRPC_INSTALL_DIR=/grpc_installed_debug
else
  echo '"$CMAKE_BUILD_TYPE" should be unset, `Debug` or `Release`.'
  exit 1
fi

mkdir -p /build_$MAKE_TARGET

echo -e '\033[1m\033[36m=== CONFIGURE ===\033[0m'
echo

cmake -DCMAKE_PREFIX_PATH="$GRPC_INSTALL_DIR" -DCMAKE_BUILD_TYPE=$MAKE_TARGET_CAMEL_CASE -G Ninja -B /build_${MAKE_TARGET} || exit 1

echo
echo -e '\033[1m\033[36m=== BUILD ===\033[0m'
echo

# NOTE(dkorolev): This is redundant, as the script is only run from within a Docker container.
if [ "$(uname)" == "Darwin" ] ; then
  CORES=$(sysctl -n hw.physicalcpu)
else
  CORES=$(nproc)
fi

cmake --build /build_${MAKE_TARGET} -j $CORES || exit 1

if [ "$GRPC_TRACE" != "" ] || [ "$GRPC_VERBOSITY" != "" ] ; then
  echo -e '\033[1m\033[36m=== GRPC DEBUG ===\033[0m'
  echo
  echo "GRPC_TRACE=$GRPC_TRACE"
  echo "GRPC_VERBOSITY=$GRPC_VERBOSITY"
fi

if [ "$GRPCPP_ONLY_BUILD" == "" ] ; then
  echo
  echo -e '\033[1m\033[36m=== RUN ===\033[0m'
  echo

  # TODO(dkorolev): A better name?
  (cd /src; /build_$MAKE_TARGET/___binary___ $*)
fi

echo
echo -e '\033[1m\033[36m=== DONE ===\033[0m'
echo
