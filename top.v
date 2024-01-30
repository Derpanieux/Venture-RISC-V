module top(clk, probe_add, probe, prog_counter, inst);
	input clk;
	input[4:0] probe_add;
	output[31:0] probe, inst, prog_counter;

	wire[31:0] imm, wd, rs1_data, rs2_data, ALU_a, ALU_b, ALU_out, mem_data, pc_offset;
	wire[4:0] rs1, rs2, rd;
	wire[3:0] ALU_op;
	wire[2:0] mem_access;
	wire[1:0] reg_wd_mux, ALU_A_mux, ALU_B_mux, pc_offset_mux;
	wire zero, reg_write, mem_write;
	
	reg[31:0] pc_plus_4;
	
	always @(prog_counter) pc_plus_4 = prog_counter + 4;
	
	controller contr_mod(
		.inst(inst),
		.zero(zero),
		.imm(imm),
		.rs1(rs1),
		.rs2(rs2),
		.rd(rd),
		.reg_write(reg_write),
		.reg_wd_mux(reg_wd_mux),
		.ALU_op(ALU_op),
		.ALU_A_mux(ALU_A_mux),
		.ALU_B_mux(ALU_B_mux),
		.pc_offset_mux(pc_offset_mux),
		.mem_write(mem_write),
		.mem_access(mem_access)
	);
	
	register_file rf_mod(
		.clk(clk),
		.A1(rs1),
		.A2(rs2),
		.A3(rd),
		.WD3(wd),
		.WE3(reg_write),
		.RD1(rs1_data),
		.RD2(rs2_data),
		.Ap(probe_add),
		.probe(probe)
	);
	
	ALU alu_mod(
		.A(ALU_a),
		.B(ALU_b),
		.op(ALU_op),
		.out(ALU_out),
		.zero(zero)
	);
	
	mem_controller mem_mod(
		.clk(clk),
		.we(mem_write),
		.access(mem_access),
		.data_address(ALU_out),
		.rd_data(mem_data),
		.wd(rs2_data),
		.inst_address(prog_counter),
		.rd_inst(inst)
	);
	
	prog_count pc_mod(
		.clk(clk),
		.offset(pc_offset),
		.pc(prog_counter)
	);
	
	mux reg_wd(
		.sel(reg_wd_mux),
		.out(wd),
		.A(ALU_out),
		.B(mem_data),
		.C(pc_plus_four)
	);
	
	mux ALU_A(
		.sel(ALU_A_mux),
		.out(ALU_a),
		.A(rs1_data),
		.B(prog_counter),
		.C(imm)
	);
	
	mux ALU_B(
		.sel(ALU_B_mux),
		.out(ALU_b),
		.A(rs2_data),
		.B(imm),
		.C(0)
	);
	
	mux pc_off(
		.sel(pc_offset_mux),
		.out(pc_offset),
		.A(4),
		.B(imm),
		.C(ALU_out)
	);
	
endmodule
