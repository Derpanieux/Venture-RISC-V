module controller (inst, zero, 
						imm,
						rs1, rs2, rd,
						reg_write, reg_wd_mux,
						ALU_op, ALU_A_mux, ALU_B_mux,
						pc_offset_mux,
						mem_write, mem_access
						);
	input [31:0] inst;
	input zero;
	output reg [31:0] imm;
	output [4:0] rs1, rs2, rd;
	output reg [3:0] ALU_op;
	output [2:0] mem_access;
	
	output reg [1:0]
						//reg_wd_mux 0 for ALU out, 1 for mem, 2 for pc + 4
						reg_wd_mux,
						
						//ALU_A_mux 0 for RD1, 1 for PC, 2 for imm
						ALU_A_mux,
	
						//ALU_B_mux 0 for RD2, 1 for imm, 2 for zero
						ALU_B_mux, 
						
						//PC_offset_mux 0 for 4, 1 for imm, 2 for ALU out, 
						pc_offset_mux;
						
	output reg 	
					reg_write, mem_write;
	
	wire [6:0] opcode, funct7;
	wire [2:0] funct3;
	wire [31:0] I_imm, S_imm, B_imm, U_imm, J_imm;
	
	inst_decoder decode(inst, opcode, rs1, rs2, rd, funct7, funct3, I_imm, S_imm, B_imm, U_imm, J_imm);
	
	assign mem_access = funct3;
	
	always @(*) begin
		case (opcode)
			//R-Types
			7'b0110011:	begin
								imm = 32'dx; // immediate value doesn't matter because we are not using it
								reg_write = 1; //writing result to reg
								reg_wd_mux = 0; //write data comes from ALU
								ALU_op[3] = funct7[5];
								ALU_op[2:0] = funct3;
								ALU_A_mux = 0; //data from RD1
								ALU_B_mux = 0; //data from RD2
								pc_offset_mux = 0; //add 4 to program counter
								mem_write = 0; //do not write to memory
							end
							
			//I-type operation instructions
			7'b0010011:	begin
								if(funct3 == 3'b001 | funct3 == 3'b101) begin
									//shift I type
									imm = rs2; //imm = shamt = rs2
									reg_write = 1; // write results to reg
									reg_wd_mux = 0; // write data from ALU
									ALU_op[3] = funct7[5]; //sets shift
									ALU_op[2:0] = funct3;
									ALU_A_mux = 0; //data from RD1
									ALU_B_mux = 1; //data from imm
									pc_offset_mux = 0; //add 4 to program counter
									mem_write = 0; //do not write to memory
								end
								else begin
									//other I type
									imm = I_imm; //i type immediate
									reg_write = 1; // write result to register
									reg_wd_mux = 0; // write data from ALU
									ALU_op[3] = 0; //set ALU op
									ALU_op[2:0] = funct3;
									ALU_A_mux = 0; // data from RD1
									ALU_B_mux = 1; //data from imm
									pc_offset_mux = 0; //add 4 to program counter
									mem_write = 0; //do not write to memory
								end
							end
							
			//I-type load instructions
			7'b0000011:	begin
								imm = I_imm;
								reg_write = 1; //write to register
								reg_wd_mux = 1; //write from memory
								ALU_op = 4'b0000; //set ALU to add
								ALU_A_mux = 0; // add RD1
								ALU_B_mux = 1; // and imm
								pc_offset_mux = 0; //add 4 to pc
								mem_write = 0; //do not write to memory
							end
			
			//S-type store instructions
			7'b0100011: begin
								imm = S_imm;
								reg_write = 0; //do not write to register
								reg_wd_mux = 2'bxx; //not writing, doesn't matter
								ALU_op = 4'b0000; //set ALU to add
								ALU_A_mux = 0; // add RD1
								ALU_B_mux = 1; // and imm
								pc_offset_mux = 0; //add 4 to pc
								mem_write = 1; //write to memory
							end
							
			//B-type instruction
			7'b1100011: begin
								imm = B_imm; //set immediate to b type
								reg_write = 0; //do not write to reg
								reg_wd_mux = 2'bxx; //does not matter what reg write data is
								mem_write = 0; // do not write to mem
								pc_offset_mux[1] = 0;
								case(funct3) //set ALU_op and pc_offset_mux
									3'b000 : begin //BEQ
													ALU_op = 4'b1000; //set SUB
													pc_offset_mux[0] = zero; //branch if zero, because they are equal
												end
									3'b001 : begin //BNE
													ALU_op = 4'b1000; //set SUB
													pc_offset_mux[0] = ~zero; // will be zero if equal, branch if not equal
												end
									3'b100 : begin //BLT
													ALU_op = 4'b0010; //set SLT
													pc_offset_mux[0] = ~zero; // if its 1 branch, if zero do not
												end
									3'b101 : begin //BGE
													ALU_op = 4'b0010; //set SLT
													pc_offset_mux[0] = zero; //if it is zero branch, because not less
												end
									3'b110 : begin //BLTU
													ALU_op = 4'b0011; //set SLTU
													pc_offset_mux[0] = ~zero; // same as BLT with different op
												end
									3'b111 : begin //BGEU
													ALU_op = 4'b0011; //set SLTU
													pc_offset_mux[0] = zero; // same as BGE with different op
												end
									default:	begin //default
													ALU_op = 4'bxxxx; 
													pc_offset_mux[0] = 1'bx;
												end
								endcase
								ALU_A_mux = 0;
								ALU_B_mux = 0;
							end
							
			//Load Upper Immediate
			7'b0110111: begin
								imm = U_imm; // U immediate
								reg_write = 1; // write to register
								reg_wd_mux = 0; // write data from ALU
								ALU_op = 4'b0000; // set ALU to ADD
								ALU_A_mux = 2; //add immediate
								ALU_B_mux = 2; // and zero
								pc_offset_mux = 0; // add 4 to prog counter
								mem_write = 0; // do not write to memory
							end
							
			//Add Upper Immediate Program Counter
			7'b0010111:	begin
								imm = U_imm; // U immediate
								reg_write = 1; //write to register
								reg_wd_mux = 0; //write from ALU
								ALU_op = 4'b0000; // set ALU to ADD
								ALU_A_mux = 1; //PC
								ALU_B_mux = 1;	// and immediate
								pc_offset_mux = 0; //add 4 to program counter
								mem_write = 0; //do not write to memory
							end
							
			//Jump and Link
			7'b1101111:	begin
								imm = J_imm; // J immediate
								reg_write = 1;	//write to reg
								reg_wd_mux = 3; //write pc + 4
								ALU_op = 4'bxxxx;// set ALU to anything, it doesn't matter
								ALU_A_mux = 2'bx;
								ALU_B_mux = 2'bx;
								pc_offset_mux = 1; //jump by immediate value
								mem_write = 0; //do not write to memory
							end
							
			//Jump and Link register
			7'b1100111:	begin
								imm = I_imm;
								//write to reg pc + 4
								reg_write = 1; // write to reg
								reg_wd_mux = 3; // pc + 4;
								ALU_op[3] = 0; // set ALU to ADD
								ALU_op[2:0] = funct3; // set from instr
								ALU_A_mux = 0; // add rs1
								ALU_B_mux = 1; // and imm
								pc_offset_mux = 2; //jump by ALU value
								mem_write = 0; // do not write to memory
							end

			7'b0000000:	begin		
								imm = 32'hx;
								reg_write = 1'hx;
								reg_wd_mux = 2'hx;
								ALU_op = 4'hx;
								ALU_A_mux = 2'hx;
								ALU_B_mux = 2'hx;
								pc_offset_mux = 2'hx;
								mem_write = 1'hx;
								//if the instruction is all 0 interpret it it as a stop
								if(inst == 0) begin
									imm = 32'hx;
									reg_write = 0;
									reg_wd_mux = 2'hx;
									ALU_op = 0; // add
									ALU_A_mux = 0; // rs1 (will be x0 since inst = 0
									ALU_B_mux = 0;	// rs2 (also x0 for same reason)
									pc_offset_mux = 2; //jump by ALU value (0). Program will not advance.
									mem_write = 0;
								end
							end
							
			default:		begin					
								//it does not matter what anything is because it is not a supported instruction
								imm = 32'hx;
								reg_write = 1'hx;
								reg_wd_mux = 2'hx;
								ALU_op = 4'hx;
								ALU_A_mux = 2'hx;
								ALU_B_mux = 2'hx;
								pc_offset_mux = 2'hx;
								mem_write = 1'hx;
							end
		endcase
	end
endmodule
	
//gets immediates and all fields from an instruction
module inst_decoder(inst, opcode, 
						rs1, rs2, rd, funct7, funct3, 
						I_imm, S_imm, B_imm, U_imm, J_imm);
	input [31:0] inst;
	output [6:0] opcode, funct7;
	output [4:0] rs1, rs2, rd;
	output [2:0] funct3;
	output reg [31:0] I_imm, S_imm, B_imm, U_imm, J_imm;
	
	reg[31:0] S_inb, B_inb, J_inb;
	
	assign opcode = inst[6:0];
	assign rs1 = inst[19:15];
	assign rs2 = inst[24:20];
	assign rd = inst[11:7];
	assign funct7 = inst[31:25];
	assign funct3 = inst[14:12];	
	
	always @(inst) begin
		I_imm = inst >>> 20;
		
		S_inb[31:25] = inst[31:25];
		S_inb[24:20] = inst[11:7];
		S_imm = S_inb >>> 20;
		
		B_inb[31] = inst[31];
		B_inb[30] = inst[7];
		B_inb[29:24] = inst[30:25];
		B_inb[23:20] = inst[11:8];
		B_imm = B_inb >>> 19;
		
		U_imm[31:12] = inst[31:12];
		U_imm[11:0] = 0;
		
		J_inb[31] = inst[31];
		J_inb[30:23] = inst[19:12];
		J_inb[22] = inst[20];
		J_inb[21:16] = inst[30:25];
		J_inb[15:12] = inst[24:21];
		J_imm = J_inb >>> 11;
		
	end			
						
endmodule
