#!/bin/bash

VERSION=$(git rev-parse --short HEAD)

echo "Building tag $VERSION"

time docker buildx build --push --tag docker.io/crnt/grpcpp:${VERSION} --platform linux/amd64,linux/arm64/v8 .
time docker buildx build --push --tag docker.io/crnt/grpcpp:latest --platform linux/amd64,linux/arm64/v8 .
