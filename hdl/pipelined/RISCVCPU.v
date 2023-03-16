`timescale 1ns/10ps

module RISCV_top
#(parameter M = 10,
  parameter N = 10,
  parameter N2 = 10,
  parameter REG_WIDTH = 32)
(CLOCK_50, rstn, done, instr_count, clock_count);


localparam LW    = 7'b000_0011;
localparam SW    = 7'b010_0011;
localparam BEQ   = 7'b110_0011;
localparam NOP   = 32'h0000_0000;
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
reg [REG_WIDTH-1:0] IDEXA, IDEXB;
reg [REG_WIDTH-1:0] EXMEMB, EXMEMALUout;
reg [REG_WIDTH-1:0] MEMWBValue;

reg  [31:0] IDEXIR, IDEXIRn, EXMEMIR, EXMEMIRn, MEMWBIR, MEMWBIRn;
wire [31:0] IFIDIR;
// wire [31:0] RealIR = stall ? NOP : IFIDIR;
wire [4:0] IFIDrs1, IFIDrs2;
reg [4:0] IDEXrs1, IDEXrs2, EXMEMrs1, EXMEMrs2;
wire [6:0] IFIDop;
assign IFIDrs1 = IFIDIR[19:15];
assign IFIDrs2 = IFIDIR[24:20];
assign IFIDop = IFIDIR[6:0];

wire [6:0]  ALUop_funct7 = IDEXIR[31:25];
wire [2:0]  Branch_funct3 = IDEXIR[14:12];

reg WB_done;

reg  [6:0] IDEXop, EXMEMop, MEMWBop;

wire [4:0] Regrd = IFIDIR[11:7];
reg  [4:0] IDEXrd, EXMEMrd, MEMWBrd;

wire [31:0] I_Mem_Out;
wire [REG_WIDTH-1:0] D_out;
reg  [REG_WIDTH-1:0] D_entry;
wire [31:0] PC_addr = PC >> 2;

wire PCOffset = {{22{IDEXIR[31]}}, IDEXIR[7], IDEXIR[30:25], IDEXIR[11:8], 1'b0};

wire bypassAfromMEM, bypassAfromALUinWB,
	 bypassBfromMEM, bypassBfromALUinWB,
	 bypassAfromLDinWB, bypassBfromLDinWB;
wire stall;

wire FuncCode = {IFIDIR[30], IFIDIR[14:12]};
reg [3:0]  IDEXFuncCode;
reg [31:0] ImmGen, ImmGen_c;

reg [31:0] PC_branch, IDEXPC;
reg ZERO;
reg [REG_WIDTH-1:0] ALUOut, WBALUOut;
reg [REG_WIDTH-1:0] WBValue;

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

// assign stall = (MEMWBop == LW) || ( // source instruction is a load
// 			   (((IDEXop == LW) || (IDEXop == SW)) && (IDEXrs1 == MEMWBrd)) || // stall for address calc
// 			   (((IDEXop == ALUop) || (IDEXop == ADDI)) && (((IFIDrs1 == IDEXrd)||(IFIDrs2 == IDEXrd)) || ((IDEXrs1 == EXMEMrd)||(IDEXrs2 == EXMEMrd)) || ((EXMEMrs1 == MEMWBrd)||(EXMEMrs2 == MEMWBrd))) && (IFIDrs1 != 0))); // ALU use

assign stall = (MEMWBop == LW) || ( // source instruction is a load
			   (((IDEXop == LW) || (IDEXop == SW)) && (IDEXrs1 == MEMWBrd)) || // stall for address calc
			   (((IDEXop == ALUop) || (IDEXop == ADDI)) && (((IDEXrs1 == EXMEMrd)||(IDEXrs2 == EXMEMrd)) || ((EXMEMrs1 == MEMWBrd)||(EXMEMrs2 == MEMWBrd))) && (IFIDrs1 != 0))); // ALU use

// assign stall = 1'b0;

wire [31:0] DMem_addr_w = ALUOut >> 2;

reg IDEXMemtoReg, EXMEMMemtoReg, MEMWBMemtoReg, IDEXMemWrite, EXMEMMemWrite;

RAM #(32, 56, "IMemory.txt") I_Memory(.wr_en(1'b0),
                                      .read_en(~stall),
									  .index(PC_addr),
									  .entry(32'b0),
									  .entry_out(IFIDIR),
									  .clk(CLOCK_50));

RAM #(REG_WIDTH, M*N+N*N2+M*N2, "DMemory.txt") D_Memory(.wr_en(EXMEMMemWrite),
                                                        .read_en(1'b1),
												        .index(DMem_addr_w),
												        .entry(D_entry),
												        .entry_out(D_out),
												        .clk(CLOCK_50));

wire [3:0]           ALUCtl;
wire [REG_WIDTH-1:0] Ain, Bin;


reg IDEXBranch, EXMEMBranch;
reg IDEXALUSrc;
reg [1:0] IDEXALUop;
reg ISLESSTHAN;
reg [31:0] IFIDPC, EXMEMPC, PCSum;
reg [REG_WIDTH-1:0] IDEXA_c, IDEXB_c, write_back_val;
wire ALUSrc, ALUSrc_w, PCSrc, MemRead, MemWrite, RegWrite, MemtoReg, Branch, islessthan, RegWrite_w;
assign PCSrc = EXMEMBranch && ISLESSTHAN;

assign Ain = IDEXA;
assign ALUSrc = IDEXALUSrc;
assign Bin = ALUSrc ? ImmGen : IDEXB;

wire MemtoReg_w;
wire Branch_w;
wire [1:0] ALUop_w;
wire [REG_WIDTH-1:0] ALUResult;


ALUControl ALUControl(.ALUOp(IDEXALUop), .FuncCode(IDEXFuncCode), .ALUCtl(ALUCtl));

RISCVALU ALU(.ALUCtl(ALUCtl),
			 .ALUOut(ALUResult),
			 .A(Ain),
			 .B(Bin),
			 .IsLessThan(islessthan));

// Control MainControl(.opcode(RealIR[6:0]),
// 					.ALUSrc(ALUSrc),
// 					.MemtoReg(MemtoReg),
// 					.RegWrite(RegWrite),
// 					.MemRead(MemRead),
// 					.MemWrite(MemWrite),
// 					.Branch(Branch),
// 					.ALUOp(ALUop));

wire [6:0] ControlInOp = stall ? NOP[6:0] : IFIDIR[6:0];

Control MainControl(.opcode(ControlInOp),
					.MemtoReg(MemtoReg_w),
					.ALUSrc(ALUSrc_w),
					.ALUOp(ALUop_w),
					.Branch(Branch_w),
                    .MemRead(MemRead_w),
                    .MemWrite(MemWrite_w),
					.RegWrite(RegWrite_w));				

integer i;
always @(posedge CLOCK_50) begin
	clock_count <= clock_count + 1;
	PC <= PCn;
	IFIDPC <= PC;

	////////////////// ID/EX Stage /////////////////////
	if (IFIDIR == EOF) begin
		done <= 1;
	end
	IDEXPC <= IFIDPC;
	// IDEXA <= Regs[IDEXrs1];
	// IDEXB <= Regs[IDEXrs2];
	IDEXrs1 <= IFIDrs1;
	IDEXrs2 <= IFIDrs2;
	ImmGen <= ImmGen_c;
	IDEXFuncCode <= FuncCode;
	IDEXrd <= Regrd;
	IDEXop <= IFIDIR[6:0];
	IDEXMemtoReg <= MemtoReg_w;
	IDEXBranch <= Branch_w;
	IDEXALUSrc <= ALUSrc_w;
	IDEXALUop <= ALUop_w;
    Regs[MEMWBrd] <= write_back_val;
    IDEXMemWrite <= MemWrite_w;
	instr_count <= instr_count_n;
	///////////// END ID/EX Stage ///////////////////////

	////////////////////// EX/MEM Stage ///////////////
	EXMEMPC <= PCSum;
	EXMEMrs1 <= IDEXrs1;
	EXMEMrs2 <= IDEXrs2;
	ISLESSTHAN <= islessthan;
	ALUOut <= ALUResult;
	EXMEMB <= IDEXB;
	EXMEMrd <= IDEXrd;
	EXMEMop <= IDEXop;
	EXMEMMemtoReg <= IDEXMemtoReg;
	EXMEMBranch <= IDEXBranch;
    EXMEMMemWrite <= IDEXMemWrite;
	/////////////////////// END EX/MEM Stage ///////////

	/////////////////////// MEM/WB Stage ///////////////
	WBALUOut <= ALUOut;
	MEMWBrd <= EXMEMrd;
	MEMWBop <= EXMEMop;
	MEMWBMemtoReg <= EXMEMMemtoReg;
	/////////////////////// END MEM/WB Stage ///////////

	if (!rstn) begin
		done <= 0;
		PC <= 0;
		IFIDPC <= 0;
		IDEXPC <= 0;
		IDEXA <= 0;
		IDEXrs1 <= 0;
		IDEXrs2 <= 0;
		EXMEMrs1 <= 0;
		EXMEMrs2 <= 0;
		IDEXB <= 0;
		ImmGen <= 0;
		IDEXFuncCode <= 0;
		IDEXrd <= 0;
		PCSum <= 0;
        ISLESSTHAN <= 0;
		ALUOut <= 0;
		EXMEMB <= 0;
		EXMEMrd <= 0;
		WBALUOut <= 0;
		MEMWBrd <= 0;
		clock_count <= 0;
		instr_count <= 0;
		MEMWBop <= 0;
		IDEXop <= 0;
		IDEXMemtoReg <= 0;
		IDEXBranch <= 0;
		IDEXALUSrc <= 0;
		IDEXALUop <= 0;
		IDEXMemWrite <= 0;
		EXMEMPC <= 0;
		EXMEMop <= 0;
		EXMEMMemtoReg <= 0;
		EXMEMBranch <= 0;
		EXMEMMemWrite <= 0;
		MEMWBMemtoReg <= 0;
		for(i = 0; i <= 31; i = i + 1) Regs[i] <= 32'b0;
	end
end

always @(*) begin
	instr_count_n = instr_count;
	PCn = 0;
	ImmGen_c = ImmGen;
	PCSum = 0;

	PCn = stall ? PC : (PCSrc ? PCSum : PC + 4);

	IDEXA = Regs[IFIDrs1];
	IDEXB = Regs[IFIDrs2];

	if ((IFIDop == LW) || (IFIDop == ADDI)) begin
		ImmGen_c = IFIDIR[31:20];
	end else if (IFIDop == SW) begin
		ImmGen_c = {IFIDIR[31:25], IFIDIR[11:7]};
	end else if (IFIDop == B_I) begin
		ImmGen_c = PCOffset;
	end
	
	instr_count_n = instr_count + 1;
	/////////////////// END ID/EX Stage //////////////

	//////////////////// EX/MEM Stage ////////////////
	PCSum = IDEXPC + ImmGen;
	D_entry = EXMEMB;
	///////////////////// END EX/MEM Stage /////////////

	///////////////////////// MEM/WB Stage ////////////////
    write_back_val = MEMWBMemtoReg ? D_out : WBALUOut;
	// Regs[MEMWBrd] = ;
	//////////////////////// END MEM/WB Stage /////////////

end

endmodule
