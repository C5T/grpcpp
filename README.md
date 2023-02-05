# grpcpp

Build and run C++ gRPC code with a one-liner under Docker.

**TODO(dkorolev)**: Actually put together a Docker-first use case!

## TL;DR

Using C++ with gRPC and protobuf can be tricky. Let's make it trivial, lightning-fast, and reproducible.

## Elevator Pitch

Enabled by `grpcpp`, C++ becomes a scripting language for all intents and purposes. 

This "scripting C++" includes full gRPC support, as well as the `current` framework, out of the box. With fast, incremental, fully optimized builds.

Synopsis: `grpcpp <dir_with_cc_source> [<more_dirs>] [flags]`. Enabled by `alias grpcpp=...` as descibed below.

## Objective

For "script-like" C++ examples that use gRPC, it's nice to have a quick way to share these examples with friends and colleagues.

In my case, I mostly use Ubuntu, while they mostly use macOS. Building gRPC binaries with C++ is painful by itself. Doubly so when multple platforms are involved. And developers don't like pain.

The solution I came up with is to have a Docker container that does one thing: build and run C++ code that uses gRPC / protobufs.

## Usage

The Docker container built from this repo, published as `crnt/grpcpp`, is all you need. Start from:

```
docker pull crnt/grpcpp
```

You would then need a directory with one `.cc` file, and one or more `.proto` files. Plenty of examples can be found under `examples/` in this repository.

When running the container, mount the directory that contains this one `.cc` file as `-v $DIR:/src`.

(You can have no `.proto` files. The current version of the container would just create one `dummy.proto` file then, for the run to succeed.)

For a trivial example:

```
git clone https://github.com/c5t/grpcpp
cd grpcpp
docker run -v $PWD/examples/hw:/src crnt/grpcpp
```

The above should print `Hello, World!`, between `=== RUN ===` and `=== DONE ===`, towards the end of terminal output.

You can also pass `-v $PWD/build:/build`. It would cache build results on the host machine. This might come in handy if frequent rebuilds are part of your routine.

For a loopback gRPC example, let's run a test first:

```
docker run -v $PWD/examples/test_add:/src -t crnt/grpcpp
```

Don't forget `-t`, otherwise the terminal output of the test itself would not be green. In fact, prefer `-it`, as this allows to `Ctrl+C` the running container, because otherwise you'd need to use `docker stop` to do so.

For a true gRPC example, there's `examples/service_mul`.

In one terminal, run:

```
docker run --network host -v $PWD/examples/service_mul:/src -it crnt/grpcpp --server 5001
```

In another terminal:

```
docker run --network host -v $PWD/examples/service_mul:/src -it crnt/grpcpp --client localhost:5001
```

## Shortcut

On Linux, consider addding `alias grpcpp=/path/to/grpcpp/grpcpp.sh` into your `.bashrc`.

This would make it simple to run `grpcpp some_dir --optional --flag_value=42` to run `grpcpp` on `some_dir` under `$PWD`.

The script would use `.build_some_dir` as the build directory, created and owned by the right user. So, a) you would have no problems cleaning up after the container, and b) the build results are cached automatically, so that the consecutive runs would be instant, and/or requiring only minimum rebuilds.

With this shortcut, the `hw` example can be run with `grpcpp examples/hw`, and the `service_mul` example is just:

```
grpcpp examples/service_mul --server 5001            # In one terminal.
grpcpp examples/service_mul --client localhost:5001  # In another terminal.
```

Happy gRPC-ing!
