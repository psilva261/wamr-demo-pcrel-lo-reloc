FROM debian:trixie

RUN apt-get update && \
    apt-get install -y build-essential git golang-go less \
                       g++-riscv64-linux-gnu gcc-riscv64-linux-gnu \
                       vim qemu-user qemu-system-riscv \
                       file wget cmake python3 python3-pip \
                       python3-tomli python3-venv ninja-build \
                       ccache autoconf automake autotools-dev curl \
                       libmpc-dev libmpfr-dev libgmp-dev gawk \
                       build-essential bison flex texinfo gperf libtool \
                       patchutils bc zlib1g-dev libexpat-dev ninja-build \
                       git cmake libglib2.0-dev libslirp-dev libncurses-dev

# Build RISC-V GNU Toolchain
#
# Seems to be necessary for soft float support e.g. for __eqsfs2 to be implemented
RUN git clone https://github.com/riscv/riscv-gnu-toolchain /tmp/riscv-gnu-toolchain && \
    cd /tmp/riscv-gnu-toolchain && \
    ./configure \
        --prefix=/opt/riscv-newlib \
        --with-arch=rv64ima \
        --enable-gdb \
        --with-cmodel=medany && \
    make -j$(nproc) linux && \
    cd / && \
    rm -rf /tmp/riscv-gnu-toolchain

RUN wget https://github.com/bytecodealliance/wasm-micro-runtime/releases/download/WAMR-2.4.4/wamrc-2.4.4-x86_64-ubuntu-22.04.tar.gz && \
    tar xf wamrc-2.4.4-x86_64-ubuntu-22.04.tar.gz && \
    mv wamrc /usr/local/bin/ && \
    rm wamrc-2.4.4-x86_64-ubuntu-22.04.tar.gz

#RUN git clone https://github.com/bytecodealliance/wasm-micro-runtime.git /wamr

# Use patched WAMR
RUN git clone https://github.com/no1wudi/wasm-micro-runtime.git /wamr
WORKDIR /wamr
RUN git checkout riscv

# # Register necessary symbols
RUN sed -i "/SymbolMap target_sym_map/a REG_SYM(__eqsf2)," /wamr/core/iwasm/aot/arch/aot_reloc_riscv.c

RUN mkdir /wamr-build
WORKDIR /wamr-build
RUN cmake ../wamr \
        -DWAMR_BUILD_PLATFORM=linux \
        -DWAMR_BUILD_TARGET=AOT \
        -DWAMR_BUILD_LIBC_BUILTIN=1 \
        -DWAMR_BUILD_INTERP=1 \
        -DWAMR_BUILD_FAST_INTERP=0 \
        -DCMAKE_SYSTEM_PROCESSOR=riscv64 \
        -DWAMR_BUILD_TARGET=RISCV64_LP64 \
        -DCMAKE_C_COMPILER=/opt/riscv-newlib/bin/riscv64-unknown-linux-gnu-gcc \
        -DCMAKE_CXX_COMPILER=/opt/riscv-newlib/bin/riscv64-unknown-linux-gnu-g++ \
        -DCMAKE_ASM_COMPILER=/opt/riscv-newlib/bin/riscv64-unknown-linux-gnu-gcc \
        -DWASM_ENABLE_SIMDE=OFF \
        -DWAMR_BUILD_SIMD=0 && \
    make

RUN mkdir /demo
COPY ./demo /demo
WORKDIR /demo
RUN go mod download

WORKDIR /demo
