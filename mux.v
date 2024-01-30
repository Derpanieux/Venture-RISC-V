
module mux(A, B, C, sel, out);
	input[31:0] A, B, C;
	input[1:0] sel;
	output reg[31:0] out;
	
	always @(*) begin
		case (sel)
			default: out = A;
			1: out = B;
			2: out = C;
		endcase
	end
endmodule
