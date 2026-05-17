/*********************************************************************************
 * RV32I SINGLE-CYCLE PROCESSOR TOP MODULE
 * -------------------------------------------------------------------------------
 * This is the heart of the processor! It connects all the sub-modules together
 * to form a complete datapath. Because it is "single-cycle", every instruction
 * completely finishes in exactly one clock tick.
 *
 * HIGH-LEVEL DATAPATH FLOW:
 *
 *  [PC] ---> [Instruction Memory] ---> [Control Unit]
 *    |                 |                      |
 *    |                 v                      v
 *    |           [Registers] ---> [ALU] ---> [Data Memory]
 *    |                 |            |              |
 *    +-----------------+------------+--------------+---> Write Back to Registers
 *
 *********************************************************************************/
module rv32i_single_cycle #(
    parameter XLEN = 32
)(
    input clk,
    input rst_n
);

    // =========================================================================
    // 1. INSTRUCTION FETCH (IF)
    // =========================================================================
    // The Program Counter (PC) holds the address of the current instruction.
    reg [XLEN-1:0] PC;
    wire [XLEN-1:0] PC_next;

    // Fetch the 32-bit instruction from memory using the PC.
    wire [XLEN-1:0] instr;

    instruction_memory imem(
        .addr(PC),
        .instr(instr)
    );

    // =========================================================================
    // 2. INSTRUCTION DECODE (ID) & CONTROL
    // =========================================================================
    // Slice the 32-bit instruction into its specific fields according to RISC-V.
    wire [6:0] opcode   = instr[6:0];
    wire [4:0] rd       = instr[11:7];      // Destination register
    wire [2:0] funct3   = instr[14:12];     // Function identifier (e.g., ADD vs SUB)
    wire [4:0] rs1      = instr[19:15];     // Source register 1
    wire [4:0] rs2      = instr[24:20];     // Source register 2
    wire [6:0] funct7   = instr[31:25];     // Secondary function identifier

    // The Control Unit acts as the "brain". It looks at the opcode and turns on
    // the correct signals to steer data through the datapath multiplexers.
    wire RegWrite, MemRead, MemWrite, ALUSrc, MemToReg, Branch, Jump;
    wire [2:0] ALU_OP;

    control_unit cu(
        .op_code(opcode),
        .RegWrite(RegWrite),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),
        .MemToReg(MemToReg),
        .Branch(Branch),
        .ALU_OP(ALU_OP),
        .Jump(Jump)
    );

    // =========================================================================
    // 3. REGISTER FILE & IMMEDIATE GENERATION
    // =========================================================================
    wire [XLEN-1:0] write_data;
    wire [XLEN-1:0] read_data1;
    wire [XLEN-1:0] read_data2;

    // Read values from rs1 and rs2. If the instruction writes back, it saves to rd.
    register_file rf(
        .clk(clk),
        .rst_n(rst_n),
        .reg_write(RegWrite),
        .rd(rd),
        .write_data(write_data),
        .rs1(rs1),
        .rs2(rs2),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // Extract and sign-extend the immediate value hidden inside the instruction.
    wire [XLEN-1:0] imm_out;
    imm_gen ig (
        .instr(instr),
        .imm_out(imm_out)
    );

    // =========================================================================
    // 4. EXECUTE (ALU)
    // =========================================================================
    // The ALU Control translates the generic ALU_OP from the main Control Unit
    // and the instruction's funct3/funct7 into a specific 4-bit ALU command.
    wire [3:0] alu_op;
    alu_control ac(
        .ALU_OP(ALU_OP),
        .funct3(funct3),
        .funct7(funct7),
        .alu_op(alu_op)
    );

    wire [XLEN-1:0] alu_input_b;
    wire [XLEN-1:0] alu_input_a;
    wire [XLEN-1:0] alu_result;
    wire zero_flag, carry_out, negative, overflow;

    // ALU Input MUX A: Choose between PC (for JAL/AUIPC), 0 (for LUI), or rs1 (default)
    assign alu_input_a =
            (Jump)? (PC) :
            (opcode == 7'b0010111)? (PC) :    // AUIPC
            (opcode == 7'b0110111)? 32'b0:    // LUI
             read_data1;

    // ALU Input MUX B: Choose between 4 (for JAL), Immediate (I/S/U-types), or rs2 (R-types)
    assign alu_input_b = (Jump)? 32'd4 : (ALUSrc)? (imm_out) : (read_data2);

    // The main mathematical brain. It computes addresses, arithmetic, and branch conditions!
    ALU_n_bit #(
        .WIDTH(32)
    ) alu (
        .op_code(alu_op),
        .a(alu_input_a),
        .b(alu_input_b),
        .c_in(1'b0),
        .answer(alu_result),
        .c_out(carry_out),
        .zero(zero_flag),
        .negative(negative),
        .overflow(overflow)
    );

    // =========================================================================
    // 5. MEMORY ACCESS (MEM) & WRITE-BACK (WB)
    // =========================================================================
    wire [XLEN-1:0] mem_data;

    // Memory module for Load/Store operations.
    // E.g., [SW x8, 4(x2)] => Memory[x2 + 4] = x8
    data_mem dm(
        .clk(clk),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .write_data(read_data2),
        .addr(alu_result),
        .read_data(mem_data)
    );

    // Write-Back MUX: Choose between Memory Data (for Loads) or ALU Result (for R/I-types)
    assign write_data = (MemToReg)? mem_data : alu_result;

    // =========================================================================
    // 6. PC UPDATE (BRANCHING & JUMPING LOGIC)
    // =========================================================================
    reg branch_taken;
    always @(*) begin
        // Evaluate the branch condition based on the ALU flags.
        case(funct3)
            3'b000 : branch_taken = zero_flag;                      // BEQ
            3'b001 : branch_taken = ~zero_flag;                     // BNE
            3'b100 : branch_taken = negative ^ overflow;            // BLT  (Signed)
            3'b101 : branch_taken = ~(negative ^ overflow);         // BGE  (Signed)
            3'b110 : branch_taken = ~carry_out;                     // BLTU (Unsigned)
            3'b111 : branch_taken = carry_out;                      // BGEU (Unsigned)
            default: branch_taken = 0;
        endcase
    end

    // Next PC Mux Logic:
    // 1. JALR -> (rs1 + imm) & ~1
    // 2. JAL or taken Branch -> PC + imm
    // 3. Normal Execution -> PC + 4
    assign PC_next = (opcode == 7'b1100111)? (read_data1 + imm_out) & (32'hFFFFFFFE)  :
                        ((Jump | (Branch & branch_taken))? (PC + imm_out) : (PC + 4));

    // Update the PC sequentially on every clock edge.
    always @(posedge clk) begin
        if(!rst_n)
            PC <= 0;
        else
            PC <= PC_next;
    end

endmodule
