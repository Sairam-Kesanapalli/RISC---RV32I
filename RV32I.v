module rv32i_single_cycle #(
    parameter XLEN = 32
)(
    input clk,
    input rst_n
);

    // PC 
    reg [XLEN-1:0] PC;
    wire [XLEN-1:0] PC_next;

    // INSTRUCTION _MEMORY
    wire [XLEN-1:0] instr;

    instruction_memory imem(
        .addr(PC),
        .instr(instr)
    );

    // DECODE
    wire [6:0] opcode   = instr[6:0];
    wire [4:0] rd       = instr[11:7];
    wire [2:0] funct3   = instr[14:12];
    wire [4:0] rs1      = instr[19:15];
    wire [4:0] rs2      = instr[24:20];
    wire [6:0] funct7    = instr[31:25];

    // CONTROL UNIT 
    wire RegWrite;
    wire MemRead;
    wire MemWrite;
    wire ALUSrc;
    wire MemToReg;
    wire Branch;
    wire Jump;
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

    // REGISTER
    wire [XLEN-1:0] write_data;
    wire [XLEN-1:0] read_data1;
    wire [XLEN-1:0] read_data2;

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

    // IMMEDIATE GENERATOR
    wire [XLEN-1:0] imm_out;

    imm_gen ig (
        .instr(instr),
        .imm_out(imm_out)
    );
    
    // ALU CONTROL LOGIC
    wire [3:0] alu_op;
    alu_control ac(
        .ALU_OP(ALU_OP),
        .funct3(funct3),
        .funct7(funct7),
        .alu_op(alu_op)
    );

    // ALU
    wire [XLEN-1:0] alu_input_b; 
    wire [XLEN-1:0] alu_input_a; 
    wire [XLEN-1:0] alu_result;
    wire zero_flag;
    assign alu_input_a = 
            (Jump)? (PC) :
            (opcode == 7'b0010111)? (PC) : 
            (opcode == 7'b0110111)? 32'b0: 
             read_data1;
    assign alu_input_b = (Jump)? 32'd4 : (ALUSrc)? (imm_out) : (read_data2);
    wire carry_out;
    wire negative;
    wire overflow;

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

    // DATA MEMORY 
    wire [XLEN-1:0] mem_data; 
    data_mem dm(
        .clk(clk),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .write_data(read_data2),        // CUZ, [SW x8, 4(x2)] => Memory[x2 + 4] = x8
        .addr(alu_result),
        .read_data(mem_data)
    );

    // WRITE BACK MUX
    assign write_data = (MemToReg)? mem_data : alu_result;
    reg branch_taken;
    always @(*) begin
        case(funct3)
            3'b000 : branch_taken = zero_flag;
            3'b001 : branch_taken = ~zero_flag;
            3'b100 : branch_taken = negative ^ overflow;
            3'b101 : branch_taken = ~(negative ^ overflow);
            3'b110 : branch_taken = ~carry_out;
            3'b111 : branch_taken = carry_out; 
        endcase
    end

    //PC UPDATE LOGIC
    assign PC_next = (opcode == 7'b1100111)? (read_data1+imm_out) & (32'hFFFFFFFE)  : 
                        ((Jump | (Branch & branch_taken))? (PC + imm_out) : (PC + 4));

    always @(posedge clk) begin
        if(!rst_n)
            PC <= 0;
        else
            PC <= PC_next; 
    end

endmodule