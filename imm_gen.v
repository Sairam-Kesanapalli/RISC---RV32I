module imm_gen #(
    parameter XLEN = 32
)(
    input [31:0] instr,
    output reg [XLEN-1:0] imm_out
);
    wire [6:0] op_code;         // 7 BIT OPCODE FOR CHECKING WHTHER ITS I, R, LOAD, STORE, BRANCH, JUMP, ETC
    assign op_code = instr[6:0];

    always @(*) begin
        case(op_code)
            // I-TYPE (ADDI, LW)
            7'b0010011,     //ADDI
            7'b0000011:
                //imm_out = {{20{instr[31]}}, instr[31:20]};

                imm_out = {{(XLEN-12){instr[31]}}, instr[31:20]};

                // IMM[11:0], RS1, FUNCT3, RD, OP_CODE
                // HERE IMM IS 12 BIT, BUT FOR ALU IT EXPECTS 32 BIT VALUE SO WE DID LIKE THIS
                // EX:- 111111111111 IS -1(1ST DIGIT IS 1 SO THE NUMBER IS NEGATIVE, TO FIND ITS MAGNITUDE TAKE 1'S COMPLEMENT AND ADD 1 FOR THIS EX:-YOU WILL GET 1 SO THE ACTUAL NUMBER IS -1)
                // FOR 32 BIT IF YOU GIVE  00000000000000000000 111111111111 IT WILL BECOME 4095
                // THEN THE ACTUAL CORRECT NUMBER WILL BE 11111111111111111111 111111111111
            
            // S-TYPE       EX:- SW x5, 8(x1)   =>      Memmory[x1+8] = x5      =>      base register is x1 and data to store is x5
            7'b0100011:
                // IMM[11:5], RS2, RS1, FUNCT3, IMM[4:0], OP_CODE
                // HERE SPLITTING IS HAPPENED CUZ RS2 OCCUPIED SOME SPACE(COMPARE WITH I TYPE)
                // BUT WE GOT SPACE IN RD REGION TO UTILISE THE SPACE REMAINING PART OF IMM WENT TO THERE
                // (SMART ENCODING SYSTEM)
                // FUNCT3 TELLS SUBPART OF THAT OP_CODE FAMILY EX:- FOR LOAD FAM-LB, LH, LW & FOR STORE FAM-SB, SH, SW
                // LW x8, 4(x2)         =>          x2=1000, given Mem[1004]=55, then x8=55
                // SW x8, 4(x2)         =>          x2=1000, given x8 is 55, then Mem[1004]=x8
                imm_out = {{(XLEN-12){instr[31]}}, instr[31:25], instr[11:7]};
            
            // B-TYPE 
            7'b1100011:
                imm_out = {
                            {(XLEN-13){instr[31]}},
                            instr[31],
                            instr[7],
                            instr[30:25],
                            instr[11:8],
                            1'b0
                            };

            //  U-TYPE
            //  LUI(LOAD UPPER IMMEDIATE), AUIPC
            7'b0110111,
            7'b0010111:
                imm_out = {
                            instr[31:12],
                            12'b0
                            };
            
            // J-TYPE 
            7'b1101111:                 // JAL
                imm_out = {
                            {{XLEN-21}{instr[31]}},
                            instr[31],
                            instr[19:12],
                            instr[20],
                            instr[30:21],
                            1'b0
                            };

            7'b1100111:
                imm_out = {
                            {{XLEN-12}{instr[31]}},
                            instr[31:20]
                            };
                            
            default:
                imm_out = {XLEN{1'b0}};
        endcase
    end
endmodule













