#!/bin/bash
set -euo pipefail

PB_VERSION=3.15.8
PB_GO_VERSION=$(go list -m all | grep google.golang.org/protobuf | awk '{print $2}')

# Create a local bin folder
LOCAL_DIR=".local"
mkdir -p "${LOCAL_DIR}"

# install a specific version of protoc
PB_REL="https://github.com/protocolbuffers/protobuf/releases"
if ! protoc --version | grep "${PB_VERSION}" >/dev/null; then
  if [[ ! -f "${LOCAL_DIR}/bin/protoc" ]]; then
    curl -sLO "$PB_REL/download/v${PB_VERSION}/protoc-${PB_VERSION}-linux-x86_64.zip"
    unzip "protoc-${PB_VERSION}-linux-x86_64.zip" -d "${LOCAL_DIR}"
    rm "protoc-${PB_VERSION}-linux-x86_64.zip"
  fi
  export PATH="${LOCAL_DIR}/bin:$PATH"
fi

###

if ! protoc --version | grep "${PB_VERSION}"; then
  echo "protoc version is not ${PB_VERSION}"
  exit 1
fi

if ! protoc-gen-go --version | grep "${PB_GO_VERSION}"; then
  echo "protoc-gen-go version is not ${PB_GO_VERSION}"
  exit 1
fi

###

# Print commands
set -x

protoc -I"./proto" -I"$GOPATH/src" --go_out="$GOPATH/src" proto/*.proto

# generate javascript code
pbjs -t static-module -w es6 -o src/proto.js \
  proto/ssl_gc_common.proto \
  proto/ssl_gc_geometry.proto \
  proto/ssl_gc_game_event.proto \
  proto/ssl_gc_referee_message.proto \
  proto/ssl_gc_change.proto \
  proto/ssl_gc_state.proto \
  proto/ssl_gc_api.proto \
  proto/ssl_gc_engine.proto

# generate typescript code for frontend v2
target_dir="./frontend/src/proto"
mkdir -p "${target_dir}"
protoc -I"./proto" \
    --plugin=./frontend/node_modules/.bin/protoc-gen-ts \
    --ts_out="${target_dir}" \
    --ts_opt=json_names \
    ./proto/ssl_gc_api.proto
# Ignore type checks for now - Generated code is not fully compatible with strict type checking: https://github.com/thesayyn/protoc-gen-ts/issues/154
sed -i '1s;^;// @ts-nocheck\n;' "${target_dir}"/*.ts
