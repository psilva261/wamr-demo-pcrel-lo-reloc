FROM debian:trixie

RUN apt-get update && \
    apt-get install -y build-essential git golang-go less \
                       g++-riscv64-linux-gnu gcc-riscv64-linux-gnu \
                       vim qemu-user qemu-system-riscv \
                       file wget cmake

RUN wget https://github.com/bytecodealliance/wasm-micro-runtime/releases/download/WAMR-2.4.4/wamrc-2.4.4-x86_64-ubuntu-22.04.tar.gz && \
    tar xf wamrc-2.4.4-x86_64-ubuntu-22.04.tar.gz && \
    mv wamrc /usr/local/bin/ && \
    rm wamrc-2.4.4-x86_64-ubuntu-22.04.tar.gz

RUN git clone https://github.com/bytecodealliance/wasm-micro-runtime.git /wamr

# # Register necessary symbols
# RUN sed -i "/SymbolMap target_sym_map/a REG_SYM(__muldi3)," /wamr/core/iwasm/aot/arch/aot_reloc_riscv.c
# RUN sed -i "/SymbolMap target_sym_map/a REG_SYM(__udivdi3)," /wamr/core/iwasm/aot/arch/aot_reloc_riscv.c
# RUN sed -i "/SymbolMap target_sym_map/a REG_SYM(__umoddi3)," /wamr/core/iwasm/aot/arch/aot_reloc_riscv.c
# RUN sed -i "/SymbolMap target_sym_map/a REG_SYM(__divdi3)," /wamr/core/iwasm/aot/arch/aot_reloc_riscv.c

RUN mkdir /wamr-build
WORKDIR /wamr-build
RUN cmake ../wamr \
        -DWAMR_BUILD_PLATFORM=linux \
        -DWAMR_BUILD_TARGET=AOT \
        -DWAMR_BUILD_LIBC_BUILTIN=1 \
        -DWAMR_BUILD_AOT=1 \
        -DCMAKE_SYSTEM_PROCESSOR=riscv64 \
        -DWAMR_BUILD_TARGET=RISCV64_LP64 \
        -DCMAKE_C_COMPILER=/usr/bin/riscv64-linux-gnu-gcc \
        -DCMAKE_CXX_COMPILER=/usr/bin/riscv64-linux-gnu-g++ \
        -DCMAKE_ASM_COMPILER=/usr/bin/riscv64-linux-gnu-gcc \
        -DWASM_ENABLE_SIMDE=OFF \
        -DWAMR_BUILD_SIMD=0 && \
    make

RUN mkdir /demo
COPY ./demo /demo
WORKDIR /demo
RUN go mod download

WORKDIR /demo
