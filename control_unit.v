module control_unit (
    input [6:0] op_code,

    output reg RegWrite,
    output reg MemRead,
    output reg MemWrite,
    output reg ALUSrc,
    output reg MemToReg,
    output reg Branch,
    output reg Jump,
    output reg [2:0] ALU_OP 
);

always @(*) begin
    case(op_code)
        7'b0010011: begin           // I-type ADDI
            RegWrite = 1;
            MemRead  = 0;
            MemWrite = 0;
            ALUSrc   = 1;   // USE IMMEDIATE
            MemToReg = 0;   // TAKE ALU RESULT
            Branch   = 0;
            Jump     = 0;
            ALU_OP   = 3'd0;
        end    

        7'b0000011: begin           // I-type LW
            RegWrite = 1;
            MemRead  = 1;
            MemWrite = 0;
            ALUSrc   = 1;   
            MemToReg = 1;   
            Branch   = 0;
            Jump     = 0;
            ALU_OP   = 3'd3;
        end    

        7'b0100011: begin           // S-type SW
            RegWrite = 0;
            MemRead  = 0;
            MemWrite = 1;
            ALUSrc   = 1;   
            MemToReg = 0;   
            Branch   = 0;
            Jump     = 0;
            ALU_OP   = 3'd3;
        end    

        7'b1100011: begin           // B-type BEQ
            RegWrite = 0;
            MemRead  = 0;
            MemWrite = 0;
            ALUSrc   = 0;   
            MemToReg = 0;   
            Branch   = 1;
            Jump     = 0;
            ALU_OP   = 3'd1;
        end  

        7'b0110011: begin           // R-type
            RegWrite = 1;
            MemRead  = 0;
            MemWrite = 0;
            ALUSrc   = 0;   
            MemToReg = 0;   
            Branch   = 0;
            Jump     = 0;
            ALU_OP   = 3'd2;
        end

        7'b0110111: begin           // U-TYPE => LUI
            RegWrite = 1;
            MemRead  = 0;
            MemWrite = 0;
            ALUSrc   = 1;   
            MemToReg = 0;   
            Branch   = 0;
            Jump     = 0;
            ALU_OP   = 3'd3;
        end

        7'b0010111: begin           // U-TYPE => AUIPC
            RegWrite = 1;
            MemRead  = 0;
            MemWrite = 0;
            ALUSrc   = 1;   
            MemToReg = 0;   
            Branch   = 0;
            Jump     = 0;
            ALU_OP   = 3'd3;
        end                 

        7'b1101111: begin           // J-TYPE
            RegWrite = 1;
            MemRead  = 0;
            MemWrite = 0;
            ALUSrc   = 1;   
            MemToReg = 0;   
            Branch   = 0;
            Jump     = 1;
            ALU_OP   = 3'd3;
        end

        7'b1100111: begin
            RegWrite = 1;
            MemRead  = 0;
            MemWrite = 0;
            ALUSrc   = 0;   
            MemToReg = 0;   
            Branch   = 0;
            Jump     = 1;
            ALU_OP   = 3'd3;
        end

        default: begin
            RegWrite = 0;
            MemRead  = 0;
            MemWrite = 0;
            ALUSrc   = 0;   
            MemToReg = 0;   
            Branch   = 0;
            Jump     = 0;
            ALU_OP   = 3'd0;
        end
    endcase
end
endmodule
