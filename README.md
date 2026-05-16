# RISC-V RV32I Single-Cycle Processor

A Verilog implementation of a 32-bit single-cycle RISC-V core (RV32I subset) with modular datapath/control blocks and a simple simulation testbench.

## Overview

This project implements a teaching-oriented RV32I CPU in a single-cycle architecture.
Each instruction completes in one clock cycle and the design is split into reusable modules:

- Top-level CPU datapath and control integration
- Register file
- Immediate generator
- ALU and ALU control
- Instruction memory and data memory
- Basic testbench

## Repository File Map

The project is organized into modular directories for clarity:

### `src/core/` (CPU Datapath & Control)
- `RV32I.v`: Top-level module (`rv32i_single_cycle`) with fetch/decode/execute/memory/writeback flow and PC update logic.
- `control_unit.v`: Main decoder generating control signals from opcode.
- `alu_control.v`: ALU operation decode from `ALU_OP`, `funct3`, and `funct7`.
- `imm_gen.v`: Immediate extraction/sign extension for I/S/B/U/J encodings.
- `register.v`: 32x32 register file (x0 hardwired to zero).

### `src/alu/` (Arithmetic Logic)
- `ALU_n_bit.v`: Parameterized ALU with arithmetic/logical/shift/compare operations.
- `full_adder_n_bit.v`: Parameterized adder used by the ALU.

### `src/memory/` (Memory Models)
- `instruction_mem.v`: Word-addressed instruction memory model.
- `data_mem.v`: Word-addressed data memory model with sync write/comb read.

### `tb/` (Testbenches)
- `rv32i_tb.v`: Basic testbench to clock/reset and run the main simulation.
- `test_lw_sw.v`: Debugging testbench for specific memory operations.

### `docs/` (Documentation)
- `DATAPATH`: ASCII pipeline-style datapath sketch.
- `formats.txt`: RISC-V instruction format notes.

## Datapath Summary

High-level flow:

1. `PC` fetches instruction from instruction memory
2. Instruction is decoded into opcode/funct/register fields
3. Control unit generates datapath control signals
4. Register file and immediate generator provide ALU inputs
5. ALU computes arithmetic/logic/address/branch compare
6. Data memory handles load/store
7. Writeback selects ALU result or load data
8. PC advances by `+4` or takes branch/jump target

## Supported Instruction Groups

Based on the current decoder/ALU implementation:

- R-type: `ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLL`, `SRL`, `SRA`, `SLT`
- I-type ALU/load path: `ADDI`, `LW`
- S-type: `SW`
- B-type branch path: `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`
- U-type: `LUI`, `AUIPC`
- J-type: `JAL`, `JALR`

## How to Simulate (Icarus Verilog)

This project uses a `Makefile` for automated compilation and simulation.

### 1) Run the Main Simulation

```bash
make all
```
This command compiles all the source files in `src/` along with the main testbench (`tb/rv32i_tb.v`) and executes the simulation, generating a VCD waveform file.

### 2) Clean Up Binaries
```bash
make clean
```

## Initial Program Loading

`instruction_mem.v` defines an instruction memory array. Add your program words in an `initial` block or load with `$readmemh` for larger test programs.

Example pattern:

```verilog
initial begin
  instr_memory[0] = 32'h00A00093; // addi x1, x0, 10
  instr_memory[1] = 32'h00500113; // addi x2, x0, 5
  // ...
end
```

## Notes and Limitations

- Design is single-cycle, so timing is limited by the longest instruction path.
- Memory model currently assumes word-aligned accesses.
- The testbench generates a waveform file `RV32I_verification.vcd` which can be opened in GTKWave to inspect signal traces.

## Future Improvements

- Add complete RISC-V architectural compliance tests.
- Add byte/halfword load-store support (e.g., `LB`, `LH`, `SB`, `SH`).
- Add synthesis scripts and timing reports.
- Transition the datapath from single-cycle to a pipelined or multi-cycle implementation.

## License

No explicit license file is currently present in the repository. Add a license if you plan to distribute or reuse this project publicly.
