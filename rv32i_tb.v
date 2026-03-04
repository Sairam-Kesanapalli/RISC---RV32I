`timescale 1ns/1ps
module rv32i_tb;
reg clk;
reg rst_n;


rv31i_single_cycle rv (
    .clk(clk),
    .rst_n(rst_n)
);

always #5 clk = ~clk;

	initial begin
	    clk = 0;
	    rst_n = 0;

	    #20;
	    rst_n = 1;

	    #400;

	    $finish;
	end
endmodule