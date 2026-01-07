#!/bin/bash

set -xe

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd $SCRIPT_DIR

GOOS=wasip1 GOARCH=wasm go build -o demo.wasm

gcc -o /usr/local/bin/file2c ./file2c.c

file2c demo.wasm wasmModuleBuffer > demo.riscv64.wamr.c

/opt/riscv-newlib/bin/riscv64-unknown-linux-gnu-gcc \
    -march=rv64gc \
    -mcmodel=medany \
    -static \
    -g \
    -I/wamr/core/iwasm/include \
    -I/wamr/core/shared/utils \
    -I/wamr/core/shared/utils/uncommon \
    -I/wamr/core/shared/platform/linux \
    main.c demo.riscv64.wamr.c \
    -liwasm \
    -L/wamr-build \
    -lc -lm -lgcc \
    -o demo.riscv64.wamr.elf

qemu-riscv64 ./demo.riscv64.wamr.elf
