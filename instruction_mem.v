module instruction_memory #(
    parameter XLEN = 32,
    parameter DEPTH = 256
)(
    input [XLEN-1:0] addr,
    output [31:0] instr
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    // INSTRUCTION MEMORY (EACH INSTRUCTION = 32 BITS)
    reg [XLEN-1:0] instr_memory [0:DEPTH-1];

/*
    initial begin
        instr_memory[0]  = 32'h00A00093;
        instr_memory[1]  = 32'h00500113;
        instr_memory[2]  = 32'h002081B3;
        instr_memory[3]  = 32'h40208233;
        instr_memory[4]  = 32'h0020F2B3;
        instr_memory[5]  = 32'h0020E333;
        instr_memory[6]  = 32'h0020C3B3;
        instr_memory[7]  = 32'h00209433;
        instr_memory[8]  = 32'h0020D4B3;
        instr_memory[9]  = 32'h4020D533;
        instr_memory[10] = 32'h001125B3;
    end
*/

    assign instr = instr_memory[addr[ADDR_WIDTH+1:2]];

endmodule