`timescale 1ns/10ps

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
localparam ADDI  = 7'b001_0011;
localparam B_I   = 7'b110_0011;
localparam EOF   = 32'hFFFF_FFFF;

localparam add = 7'b0000000;
localparam sub = 7'b0100000;
localparam mul = 7'b0000001;
localparam blt = 3'b100;
localparam beq = 3'b000;


input CLOCK_50;
input rstn; // external active low reset signal
output reg done;
output reg [31:0] clock_count;
output reg [31:0] instr_count;

reg [31:0] clock_count_n, instr_count_n;

reg [REG_WIDTH-1:0] Regs[0:31];
reg [31:0] PC, PCn; // PCn in the next cycle PC
reg [REG_WIDTH-1:0] IDEXA, IDEXB, IDEXAn, IDEXBn;
reg [REG_WIDTH-1:0] EXMEMB, EXMEMBn, EXMEMALUout;
reg [REG_WIDTH-1:0] MEMWBValue;

reg  [31:0] IDEXIR, IDEXIRn, EXMEMIR, EXMEMIRn, MEMWBIR, MEMWBIRn;
wire [31:0] IFIDIR;
wire [4:0]  IFIDrs1, IFIDrs2, MEMWBrd;
wire [6:0]  IDEXop, EXMEMop, MEMWBop;
wire [6:0]  ALUop_funct7 = IDEXIR[31:25];
wire [2:0]  Branch_funct3 = IDEXIR[14:12];

reg WB_done, wr_en;

wire [6:0] IDEXop, EXMEMop, MEMWBop;

assign IFIDrs1 = IFIDIR[19:15]; // rs1 field
assign IFIDrs2 = IFIDIR[24:20]; // rs2 field
assign IDEXrs1 = IDEXIR[19:15];
assign IDEXrs2 = IDEXIR[24:20];
assign IDEXop  = IDEXIR[6:0];   // the opcode
assign EXMEMop = EXMEMIR[6:0];  // the opcode
assign EXMEMrd = EXMEMIR[11:7]; // the read address
assign MEMWBop = MEMWBIR[6:0];  // the opcode
assign MEMWBrd = MEMWBIR[11:7]; // rd field

wire [31:0] I_Mem_Out;
wire [REG_WIDTH-1:0] D_entry, D_out;

wire PCOffset = {{22{IDEXIR[31]}}, IDEXIR[7], IDEXIR[30:25], IDEXIR[11:8], 1'b0};

wire bypassAfromMEM, bypassAfromALUinWB,
	 bypassBfromMEM, bypassBfromALUinWB,
	 bypassAfromLDinWB, bypassBfromLDinWB;
wire stall;

// // Bypass to iunput A from the MEM stage for an ALU operation
// assign bypassAfromMEM = (IDEXrs1 == EXMEMrd) && (IDEXrs1 != 0) && ((EXMEMop == ALUop) || (EXMEMop == Imm_I));
// // Bypass to input  B from the MEM stage for an ALU op
// assign bypassBfromMEM = (IDEXrs2 == EXMEMrd) && (IDEXrs2 != 0) && ((EXMEMop == ALUop) || (EXMEMop == Imm_I));
// assign bypassAfromALUinWB = (IDEXrs1 == MEMWBrd) && (IDEXrs1 != 0) && ((MEMWBop == ALUop) || (MEMWBop == Imm_I));
// assign bypassBfromALUinWB = (IDEXrs2 == MEMWBrd) && (IDEXrs2 != 0) && ((MEMWBop == ALUop) || (MEMWBop == Imm_I));
// assign bypassAfromLDinWB = (IDEXrs1 == MEMWBrd) && (IDEXrs1 != 0) && (EXMEMop == LW);
// assign bypassBfromLDinWB = (IDEXrs2 == MEMWBrd) && (IDEXrs2 != 0) && (EXMEMop == LW);

// assign Ain = bypassAfromMEM ? EXMEMALUout : (bypassAfromALUinWB || bypassAfromLDinWB) ? MEMWBValue : IDEXA;
// assign Bin = bypassBfromMEM ? EXMEMALUout : (bypassBfromALUinWB || bypassBfromLDinWB) ? MEMWBValue : IDEXB;

assign stall = (MEMWBop == LW) || ( // source instruction is a load
			   (((IDEXop == LW) || (IDEXop == SW)) && (IDEXrs1 == MEMWBrd)) || // stall for address calc
			   ((IDEXop == ALUop) && ((IDEXrs1 == MEMWBrd) ||(IDEXrs2 == MEMWBrd)))); // ALU use

RAM #(32, 56, "IMemory.txt") I_Memory(.wr_en(wr_en),
									  .index(PC_addr),
									  .entry(32'b0),
									  .entry_out(IFIDIR),
									  .clk(CLOCK_50));

RAM #(REG_WIDTH, M*N+N*N2+M*N2, "DMemory.txt") D_Memory(.wr_en(wr_en),
												 .index(DMem_addr_w),
												 .entry(D_entry),
												 .entry_out(D_out),
												 .clk(CLOCK_50));

wire [3:0]           ALUCtl;
wire [REG_WIDTH-1:0] Ain, Bin;
wire                 ZERO;
wire [1:0]           ALUop;
wire [3:0]           FuncCode = {IDEXIR[30], IDEXIR[14:12]};
wire ALUSrc, Branch, MemRead, MemWrite, RegWrite, MemtoReg;

ALUControl ALUControl(.ALUOp(ALUop), .FuncCode(FuncCode), .ALUCtl(ALUCtl));

RISCVALU ALU(.ALUCtl(ALUCtl),
			 .ALUOut(ALUResult),
			 .A(Ain),
			 .B(Bin),
			 .Zero(ZERO));

Control MainControl(.opcode(IFIDIR[6:0]),
					.ALUSrc(ALUSrc),
					.MemtoReg(MemtoReg),
					.RegWrite(RegWrite),
					.MemRead(MemRead),
					.MemWrite(MemWrite),
					.Branch(Branch),
					.ALUOp(ALUop));


integer i;
always @(posedge CLOCK_50) begin
	PC <= PCn;
	IFIRIR <= IFIDIRn;
	IDEXIR <= IDEXIRn;
	EXMEMIR <= EXMEMIRn;
	MEMWBIR <= MEMWBIRn;
	IDEXA <= IDEXAn;
	IDEXB <= IDEXBn;
	EXMEMBn <= EXMEMB;
	clock_count <= clock_count + 1;
	instr_count <= instr_count_n;
	done <= done_c;
	
	if (!rstn) begin
		PC <= 0;
		IFIRIR <= 0;
		IDEXIR <= 0;
		EXMEMIR <= 0;
		MEMWBIR <= 0;
		clock_count <= 0;
		instr_count <= 0;
		for(i = 0; i <= 31; i = i + 1) Regs[i] = 32'b0;
	end
end

always @(*) begin
	PCn = PC;
	EXMEMALUout = 0; D_entry = 0; wr_en = 0; instr_count_n = instr_count; MEMWBValue = 0; done_c = 1'b0; WB_done = 0;
	IFIDIRn = NOP; IDEXIRn = NOP; EXMEMIRn = NOP;
	EXMEMBn = 0;

	if (~stall) begin
	    // IFIDIRn = I_Mem_Out;
	    PCn = Branch ? (PC + PCOffset) : (PC + 4);
		if (IFIDIR == EOF) begin
			done_c = 1'b1;
		end
-
		IDEXAn = Regs[IFIDrs1];
		IDEXBn = Regs[IFIDrs2];

		IDEXIRn = IFIDIR;

		if (IDEXop == LW) begin
			EXMEMALUout = IDEXA + IDEXIR[31:20];
		end
		else if (IDEXop == SW) begin
			EXMEMALUout = IDEXA + {IDEXIR[31:25], IDEXIR[11:7]};
		end
		else if (IDEXop == ALUop) begin
			case(ALUop_funct7)
				add: EXMEMALUout = Ain + Bin;
				sub: EXMEMALUout = Ain - Bin;
				mul: EXMEMALUout = Ain * Bin;
				default: ;
			endcase
		end
		else if (IDEXop == ADDI) begin
			EXMEMALUout = Ain + IDEXIR[31:20];
		end
		else if (IDEXop == B_I) begin
			case(Branch_funct3)
				blt: if (Ain < Bin) PCn = PC + PCOffset;
				beq: if (Ain == Bin) PCn = PC + PCOffset;
				default: ;
			endcase
		end
		EXMEMIRn = IDEXIR;
		EXMEMBn = IDEXB;
	end else EXMEMIRn = NOP;

	instr_count_n = instr_count + 1;

	if ((EXMEMop == ALUop) || (EXMEMop == ADDI)) MEMWBValue = EXMEMALUout;
	else if (EXMEMop == LW) MEMWBValue = D_out;
	else if (EXMEMop == SW) D_entry = EXMEMB;

	MEMWBIRn = EXMEMIR;

	if (((MEMWBop == LW) || (MEMWBop == ALUop) || (MEMWBop == Imm_I)) && (MEMWBrd != 0)) begin
		Regs[MEMWBrd] = MEMWBValue;
		$display("MEMWBrd:%d", MEMWBrd);
		WB_done = 1'b1;
	end

end

endmodule
