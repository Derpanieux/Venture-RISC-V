module ALU (A, B, op, out, zero);
	input [31:0] A, B;
	input [3:0] op;
	output reg [31:0] out;
	output zero;
	
	wire signed [31:0] signedA, signedB;
	assign signedA = A;
	assign signedB = B;
	
	assign zero = ~|out;
	
	always @(A or B or op) begin
		case (op)
			//ADD
			4'b0000: out = A + B;
			
			//SUB
			4'b1000: out = A - B;
			
			//XOR
			4'b0100: out = A ^ B;
			
			//OR
			4'b0110: out = A | B;
			
			//AND
			4'b0111: out = A & B;
			
			//Shift Left
			4'b0001: out = A << B;
			
			//Shift Right Logical
			4'b0101: out = A >> B;
			
			//Shift Right Arithmetic
			4'b1101: out = A >>> B;
			
			//Set Less Than Signed
			4'b0010: out = (signedA < signedB) ? 1:0;
			
			//Set Less Than Unsigned
			4'b0011: out = (A < B) ? 1:0;
			
			default: out <= 32'hxxxxxxxx;
		endcase;
	end
endmodule
