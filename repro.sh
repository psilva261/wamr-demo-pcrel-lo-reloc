#!/bin/bash

set -xe

docker build -t wamr_repro_rv64_reloc .
docker run -it -v $(pwd)/demo:/demo -w /demo wamr_repro_rv64_reloc ./build_demo.sh
