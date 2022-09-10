# grpcpp

Build and run C++ gRPC code with a one-liner with Docker.

## TL;DR

Using C++ with gRPC and protobuf sucks. Let's make it trivial and reproducible.

## Objective

For "script-like" C++ examples that use gRPC, it's nice to have a quick way to share these examples with friends and colleagues.

In my case, I mostly use Ubuntu, while they mostly use macOS. Building gRPC binaries with C++ is tricky by itself. Doubly do when multple platforms are involved. And developers don't like pain.

The solution I came up with is to have a Docker container that does one thing: build and run C++ code that uses gRPC / protobufs.

## Usage

The Docker container built from this repo, published as `crnt/grpcpp`, is all you need. Start from:

```
docker pull crnt/grpcpp
```

You would then need a directory with one `.cc` file, and one or more `.proto` files. Plenty of examples can be found under `examples/` in this repository.

When running the container, mount this directory with `-v $DIR:/src`.

(You can have no `.proto` files. The current version of the container would just create one `dummy.proto` file then, for the run to succeed.)

For a trivial example:

```
git clone https://github.com/c5t/grpcpp
docker run -v $PWD/grpcpp/examples/hw:/src crnt/grpcpp
```

The above should print `Hello, World!`, between `=== RUN ===` and `=== DONE ===`, towards the end of terminal output.

You can also pass `-v $PWD/build:/build`. This would cache build results on the host machine. This might come in handy if frequent rebuilds are part of your routine.

For a true gRPC example, let's run a test first:

```
docker run -v $PWD/examples/test_add:/src -t crnt/grpcpp
```

Don't forget `-t`, otherwise the terminal output of the test itself would not be green.
