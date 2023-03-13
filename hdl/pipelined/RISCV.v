`timescale 1ns/10ps
// Pipelined version with no branch instructions or hazard detection
module RISCV
#(parameter M = 10,
  parameter N = 10,
  parameter N2 = 10,
  parameter REG_WIDTH = 32)
(CLOCK_50, rstn, done, instr_cnt, clock_count);


localparam LW    = 7'b000_0011;
localparam SW    = 7'b010_0011;
localparam BEQ   = 7'b110_0011;
localparam NOP   = 32'h0000_0013;
localparam ALUop = 7'b011_0011;
localparam Imm_I = 7'b001_0011;
localparam B_I   = 7'b110_0011;
localparam EOF   = 32'hFFFF_FFFF;

////////////////////// I/O /////////////////////////
input CLOCK_50;
input rstn;
output reg done;
output reg [31:0] clock_count;
output reg [31:0] instr_cnt;
///////////////////// END I/O ///////////////////


////////////// REGISTERS AND WIRES ////////////////////
reg [31:0] PC;
reg [REG_WIDTH-1:0] Regs [0:31];
// reg signed [31:0] I_Memory [0:35];
// reg signed [REG_WIDTH-1:0] D_Memory [0:M*N+N*N2+M*N2-1];
reg [31:0] IDEXA, IDEXB;
reg [31:0] EXMEMB, EXMEMALUout;
reg [31:0] MEMWBValue;

 // separate memories for instructions and data
reg [31:0] IFIDIR, IDEXIR, EXMEMIR, PREMEMIR, MEMWBIR; // pipeline registers

wire clk;
wire [4:0] IFIDrs1, IFIDrs2, MEMWBrd; // Access register fields
wire [6:0] IDEXop, EXMEMop, PREMEMop, MEMWBop; // Access opcodes
wire [31:0] Ain, Bin; // ALU inputs

reg WB_done; // asserted every time WB is done, to detect completion of program
reg wr_en;

wire [31:0] PC_addr = PC >> 2;
wire [31:0] I_Mem_Out;
wire [31:0] DMem_addr_w = EXMEMALUout >> 2;
wire signed [31:0] D_out;
reg signed  [31:0] D_entry;

// Bypass signals
wire bypassAfromMEM, bypassAfromALUinWB,
	 bypassBfromMEM, bypassBfromALUinWB,
	 bypassAfromLDinWB, bypassBfromLDinWB;
wire stall;
/////////////////END OF REGISTERS AND WIRES ////////////////


///////////// Assignments define fields from the pipeline registers
assign IFIDrs1 = IFIDIR[19:15]; // rs1 field
assign IFIDrs2 = IFIDIR[24:20]; // rs2 field
assign IDEXrs1 = IDEXIR[19:15];
assign IDEXrs2 = IDEXIR[24:20];
assign IDEXop  = IDEXIR[6:0];   // the opcode
assign EXMEMop = EXMEMIR[6:0];  // the opcode
assign EXMEMrd = EXMEMIR[11:7]; // the read address
assign PREMEMop = PREMEMIR[6:0];
assign MEMWBop = MEMWBIR[6:0];  // the opcode
assign MEMWBrd = MEMWBIR[11:7]; // rd field

// Bypass to iunput A from the MEM stage for an ALU operation
assign bypassAfromMEM = (IDEXrs1 == EXMEMrd) && (IDEXrs1 != 0) && ((EXMEMop == ALUop) || (EXMEMop == Imm_I));
// Bypass to input  B from the MEM stage for an ALU op
assign bypassBfromMEM = (IDEXrs2 == EXMEMrd) && (IDEXrs2 != 0) && ((EXMEMop == ALUop) || (EXMEMop == Imm_I));
assign bypassAfromALUinWB = (IDEXrs1 == MEMWBrd) && (IDEXrs1 != 0) && ((MEMWBop == ALUop) || (MEMWBop == Imm_I));
assign bypassBfromALUinWB = (IDEXrs2 == MEMWBrd) && (IDEXrs2 != 0) && ((MEMWBop == ALUop) || (MEMWBop == Imm_I));
assign bypassAfromLDinWB = (IDEXrs1 == MEMWBrd) && (IDEXrs1 != 0) && (EXMEMop == LW);
assign bypassBfromLDinWB = (IDEXrs2 == MEMWBrd) && (IDEXrs2 != 0) && (EXMEMop == LW);

assign Ain = bypassAfromMEM ? EXMEMALUout : (bypassAfromALUinWB || bypassAfromLDinWB) ? MEMWBValue : IDEXA;
assign Bin = bypassBfromMEM ? EXMEMALUout : (bypassBfromALUinWB || bypassBfromLDinWB) ? MEMWBValue : IDEXB;

assign stall = (MEMWBop == LW) && ( // source instruction is a load
			   (((IDEXop == LW) || (IDEXop == SW)) && (IDEXrs1 == MEMWBrd)) || // stall for address calc
			   ((IDEXop == ALUop) && ((IDEXrs1 == MEMWBrd) ||(IDEXrs2 == MEMWBrd)))); // ALU use

integer i; // used to initialize registers
// initial begin
//     PC = 0;
//     IFIDIR = NOP;
//     IDEXIR = NOP;
//     EXMEMIR = NOP;
//     MEMWBIR = NOP; // put NOPs in pipeline registers
//     for (i = 0;i <= 31;i = i+1) Regs[i] = i; // initialize registers--just so they aren't x'cares
// 	$readmemb("IMemory.txt", IMemory);
// 	$readmemb("matrix_memory.txt", matrix_memory);
// 	$readmemb("vector_memory.txt", vector_memory);

// end

clk_divid ckd(.clk(CLOCK_50), .rstn(rstn), .out_clk(clk));

RAM #(32, 56, "IMemory.txt") I_Memory(.wr_en(wr_en),
									  .index(PC_addr),
									  .entry(32'b0),
									  .entry_out(I_Mem_Out),
									  .clk(CLOCK_50));

RAM #(REG_WIDTH, M*N+N*N2+M*N2, "DMemory.txt") D_Memory(.wr_en(wr_en),
												 .index(DMem_addr_w),
												 .entry(D_entry),
												 .entry_out(D_out),
												 .clk(CLOCK_50));

///////////////////////////////////////////// PROCESSING ////////////////////////////////////////////////
always @(posedge clk or negedge rstn) begin
	clock_count <= clock_count + 1;
	wr_en <= 1'b0;
	if (~stall) begin
		// Fetch 1st instruction and increment PC
		IFIDIR <= I_Mem_Out;
		// $display("IFIDR:%b", IFIDIR);
		PC <= PC + 4;
		if (IFIDIR == EOF) begin
			done <= 1'b1;
		end else done <= 1'b0;
		WB_done <= 1'b0;

		// 2nd instruction in pipeline fetches registers
		IDEXA <= Regs[IFIDrs1]; // Get the two
		IDEXB <= Regs[IFIDrs2]; // registers
		// $display("IDEXA = %b, IDEXB = %b", IDEXA, IDEXB);

		IDEXIR <= IFIDIR; // Pass along IR -- can happen anywhere since only affects next stage

		///////////////////////////// EX Stage /////////////////////////
		// 3rd instruction doing address calculation for ALU op
		if (IDEXop == LW) begin
			EXMEMALUout <= IDEXA + IDEXIR[31:20]; // lw
			// $display("LW Branch Taken");
			// $display("%b, %b", IDEXA, IDEXIR);
			// $display("EXMEMALUout=%d", EXMEMALUout);
		end else if (IDEXop == SW) begin
			EXMEMALUout <= IDEXA + {IDEXIR[31:25], IDEXIR[11:7]}; // sw
		end else if (IDEXop == ALUop) begin
			case (IDEXIR[31:25]) // funct7 for different R-type instructions
				7'b0000000: EXMEMALUout <= Ain + Bin; // add operation
				7'b0100000: EXMEMALUout <= Ain - Bin; // sub
				7'b0000001: EXMEMALUout <= Ain * Bin; // mul
				default: ;
			endcase
		end else if (IDEXop == Imm_I) begin
			case (IDEXIR[14:12])
				3'b000: EXMEMALUout <= Ain + IDEXIR[31:20]; // addi
			endcase
		end else if (IDEXop == B_I) begin
			case(IDEXIR[14:12])
				3'b100: if (IDEXA < IDEXB) PC <= PC + {{22{IDEXIR[31]}}, IDEXIR[7], IDEXIR[30:25], IDEXIR[11:8], 1'b0}; // blt
				3'b000: if (IDEXA == IDEXB) PC <= PC + {{22{IDEXIR[31]}}, IDEXIR[7], IDEXIR[30:25], IDEXIR[11:8], 1'b0}; // beq
			endcase
		end
		EXMEMIR <= IDEXIR; // Pass along the IR
		EXMEMB <= IDEXB; // & B register
	end // end if (~stall) begin
	else EXMEMIR <= NOP;
	instr_cnt <= instr_cnt + 1;
	/////////////////////////// END EX Stage /////////////////////////

	///////////////////////////PRE MEM Stage//////////////////////////
	// PREMEMIR <= EXMEMIR;
	//////////////////////END PRE MEM Stage////////////////////////////

	////////////////////////////// MEM Stage ///////////////////////////////
	if      ((EXMEMop == ALUop) || (EXMEMop == Imm_I)) MEMWBValue <= EXMEMALUout;
	else if (EXMEMop == LW)    MEMWBValue <= D_out;
	else if (EXMEMop == SW)    D_entry <= EXMEMB;
	///////////////////////////// END MEM Stage //////////////////////////////

	MEMWBIR <= EXMEMIR; // Pass along IR

	////////////////////////////// WB Stage /////////////////////////////////
	// update registers if load/ALU op and destination not 0
	if (((MEMWBop == LW) || (MEMWBop == ALUop) || (MEMWBop == Imm_I)) && (MEMWBrd != 0)) begin
		Regs[MEMWBrd] <= MEMWBValue;
		$display("MEMWBrd:%d", MEMWBrd);
		WB_done <= 1'b1;
	end
    /////////////////////////////// END WB Stage /////////////////////////////

	if (!rstn) begin
		PC <= 0;
		clock_count <= 0;
		instr_cnt <= 0;
		wr_en <= 1'b0;
		IFIDIR <= 32'b0;
		IDEXIR <= 32'b0;
		EXMEMIR <= 32'b0;
		MEMWBIR <= 32'b0; // put NOPs in pipeline registers
		for (i = 0;i <= 31;i = i+1) Regs[i] <= 32'b0; // initialize registers--just so they aren't x'cares
	end
end
///////////////////////////////////// END PROCESSING ////////////////////////////////////////

endmodule
