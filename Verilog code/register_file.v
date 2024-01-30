//RISC-V register file module. No writing to x0.
module register_file(clk, A1, A2, A3, WD3, WE3, RD1, RD2, Ap, probe);
	input clk, WE3;
	input [4:0] A1, A2, A3, Ap;
	input [31:0] WD3;
	output reg [31:0] RD1, RD2, probe;
	
	reg[31:0] rf_regs[30:0];
	
	//set output 1
	always @(A1 or rf_regs) begin
		if(A1 == 0) RD1 <= 0;
		else RD1 <= rf_regs[A1-1];
	end
	
	//set output 2
	always @(A2 or rf_regs) begin
		if(A2 == 0) RD2 <= 0;
		else RD2 <= rf_regs[A2-1];
	end
	
	//set probe
	always @(Ap or rf_regs) begin
		if(Ap == 0) probe <= 0;
		else probe <= rf_regs[Ap-1];
	end
	
	//store input
	always @(posedge clk) begin
		if(WE3 & A3 != 0) rf_regs[A3-1] <= WD3;
	end
	
	
endmodule
