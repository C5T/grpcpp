#!/bin/bash

SRC_COUNT=$(find src/ -iname '*.cc' | wc -l)

if [ "$SRC_COUNT" == "0" ] ; then
  echo -e '\033[1m\033[36m=== USAGE ===\033[0m'
  echo
  echo 'Mount a directory under which there exists a `.cc` file as `/src`.'
  echo 'This directory may also contain or more `.proto` files.'
  echo
  echo 'The source file will be built, along with all the proto files.'
  echo 'The resulting binary will then be run.'
  echo 'The command line arguments will be passed along to this binary.'
  echo
  echo 'If there are no `.proto` files, the dummy one will be created. Sorry about this for now. -- D.K.'
  echo
  echo 'Do not forget to mount the necessary folders with data files, and to open the necessary ports.'
  echo
  echo 'You may also mount some directory as `/build`. This will have two benefits:'
  echo '1) Rebuilds will be incremental, and, thus, faster.'
  echo '2) If your host system is Ubuntu, you would be able to run the built binaries.'
  exit 0
fi

if [ "$SRC_COUNT" != "1" ] ; then
  echo -e '\033[1m\033[31mError:\033[0m Has multiple `.cc` files under `src/`. There should be one. It will be [re]built and run.'
  find src/ -iname '*.cc'
  exit 1
fi

PROTOS=$(find src/ -iname '*.proto')

if [ "$PROTOS" == "" ] ; then
  echo -e '// Autogenerated to have at least one `.proto` file. -- D.K.\nsyntax = "proto3";' >src/dummy.proto
fi

mkdir -p /build
export GRPC_PLAYGROUND_RELEASE_BUILD_DIR=/build

echo -e '\033[1m\033[36m=== CONFIGURE ===\033[0m'
echo
make --always-make /build/.configure_succeeded || exit 1

echo
echo -e '\033[1m\033[36m=== BUILD ===\033[0m'
echo

make release || exit 1

echo
echo -e '\033[1m\033[36m=== RUN ===\033[0m'
echo

SRC=$(find src/ -iname '*.cc')
/build/$(basename $SRC | sed 's/\.cc$//') $*

echo
echo -e '\033[1m\033[36m=== DONE ===\033[0m'
echo
