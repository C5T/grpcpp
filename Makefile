# NOTE(dkorolev): Copy-pasted from https://github.com/dkorolev/grpc_playground

.PHONY: debug release debug_dir release_dir clean

DEBUG_BUILD_DIR=/build_debug
RELEASE_BUILD_DIR=/build_release

NINJA=$(shell ninja --version 2>&1 >/dev/null && echo YES || echo NO)
ifeq ($(NINJA),YES)
  CMAKE_CONFIGURE_OPTIONS=-G Ninja
  CMAKE_BUILD_COMMAND=cmake --build
else
  CMAKE_CONFIGURE_OPTIONS=
  CMAKE_BUILD_COMMAND=MAKEFLAGS=--no-print-directory cmake --build
endif

ifdef GRPC_INSTALL_DIR
  CMAKE_CONFIGURE_COMMAND=cmake -DCMAKE_PREFIX_PATH="$(GRPC_INSTALL_DIR)"
else
  CMAKE_CONFIGURE_COMMAND=cmake
endif

OS=$(shell uname)
ifeq ($(OS),Darwin)
  CORES=$(shell sysctl -n hw.physicalcpu)
else
  CORES=$(shell nproc)
endif

debug: debug_dir
	${CMAKE_BUILD_COMMAND} "${DEBUG_BUILD_DIR}" -j ${CORES}

debug_dir: ${DEBUG_BUILD_DIR}/.configure_succeeded

${DEBUG_BUILD_DIR}/.configure_succeeded: CMakeLists.txt
	$(CMAKE_CONFIGURE_COMMAND) -DCMAKE_BUILD_TYPE=Debug $(CMAKE_CONFIGURE_OPTIONS) -B "${DEBUG_BUILD_DIR}" .
	touch "${DEBUG_BUILD_DIR}/.configure_succeeded" 2>/dev/null

release: release_dir
	@${CMAKE_BUILD_COMMAND} "${RELEASE_BUILD_DIR}" -j ${CORES}

release_dir: ${RELEASE_BUILD_DIR}/.configure_succeeded

${RELEASE_BUILD_DIR}/.configure_succeeded: CMakeLists.txt
	@$(CMAKE_CONFIGURE_COMMAND) -DCMAKE_BUILD_TYPE=Release $(CMAKE_CONFIGURE_OPTIONS) -B "${RELEASE_BUILD_DIR}" .
	touch "${RELEASE_BUILD_DIR}/.configure_succeeded" 2>/dev/null

clean:
	rm -rf "${DEBUG_BUILD_DIR}" "${RELEASE_BUILD_DIR}"
