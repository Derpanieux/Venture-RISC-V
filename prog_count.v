module prog_count(clk, offset, pc);
	input clk;
	input [31:0] offset;
	output reg [31:0] pc;
	
	always @(posedge clk) begin
		pc = pc + offset;
	end
endmodule
