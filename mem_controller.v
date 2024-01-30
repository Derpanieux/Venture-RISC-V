
module mem_controller(clk, data_address, inst_address, we, wd, rd_data, rd_inst, access);
	input clk, we;
	input [2:0] access; 
	// 000 = lower byte, 001 = lower half word, 010 = full word, 100 = upper byte, 101 = lower half word 
	input [WORD_WIDTH-1:0] data_address, inst_address, wd;
	output reg [WORD_WIDTH-1:0] rd_data, rd_inst;
	
	parameter WORD_WIDTH = 32;
	parameter HALF_WORD_WIDTH = 16;
	parameter BYTE_WIDTH = 8;
	
	parameter ADDR_WIDTH = 6;
	parameter RAM_SIZE = 1 << (ADDR_WIDTH - 2);
	reg [WORD_WIDTH-1:0] mem [RAM_SIZE-1:0];
	
	wire [WORD_WIDTH-3:0] data_add_real = data_address >> 2;
	wire [WORD_WIDTH-3:0] inst_add_real = inst_address >> 2;
	reg [WORD_WIDTH-1:0] rd_data_inter;
	reg [WORD_WIDTH-1:0] rd_data_inter2;
	reg [WORD_WIDTH-1:0] wd_real;

	always @(*) begin
		case (access)
			3'b000 : begin
							wd_real = 0;
							wd_real[7:0] = wd[7:0];
							rd_data_inter2 = 0;
							rd_data_inter2[31:24] = rd_data_inter[7:0];
							rd_data = rd_data_inter2 >>> 24;
						end
			3'b001 : begin
							wd_real = 0;
							wd_real[15:0] = wd[15:0];
							rd_data_inter2 = 0;
							rd_data_inter2[31:16] = rd_data_inter[15:0];
							rd_data = rd_data_inter2 >>> 16;
						end
			3'b010 : begin
							wd_real = wd;
							rd_data_inter2 = 32'hx;
							rd_data = rd_data_inter;
						end
			3'b100 : begin
							wd_real = 32'hx;
							rd_data_inter2 = 32'hx;
							rd_data = rd_data_inter[7:0] << 24;
						end
			3'b101 : begin
							wd_real = 32'hx;
							rd_data_inter2 = 32'hx;
							rd_data = rd_data_inter[15:0] << 16;
						end
			default: begin
							wd_real = 32'hx;
							rd_data_inter2 = 32'hx;
							rd_data = 32'hx;
						end
		endcase
	end
	
	always @(posedge clk) begin
		if(we) begin
			mem[data_add_real] = wd_real;
		end
		rd_data_inter = mem[data_add_real];
		rd_inst = mem[inst_add_real];
	end
	
	initial begin
		$readmemh("hex_memory.txt", mem);
	end
	
endmodule
