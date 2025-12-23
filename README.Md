# README

Minimal demo for producing special case of R_RISCV_PCREL_LO12_I/S relocation not followed by R_RISCV_PCREL_HI20 relocation on RISCV-64

To run:

```
./repro.sh
```

or

```
docker build -t wamr_repro_rv64_reloc .
docker run -it -v $(pwd)/demo:/demo -w /demo wamr_repro_rv64_reloc bash
./build_demo.sh
```

(build files get written to `./demo`)
