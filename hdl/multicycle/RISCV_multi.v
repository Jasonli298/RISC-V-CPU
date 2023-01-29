// multicycle version of the RISCV CPU
module RISCV_multi(clk);

localparam LW = 7'b000_0011;
localparam SW = 7'b010_0011;
localparam BEQ = 7'b110_0011;
localparam NOP = 32'h0000_0013;
localparam ALUop = 7'b001_0011;

input clk;

/////////////// Internal Registers //////////////////
reg [31:0] PC; // program counter
reg [0:31] Regs; // register file
reg [31:0] IR; // instruction register
reg [31:0] MDR; // memory data register
reg [31:0] A, B; // two ALU inputs
reg [31:0] Memory[0:1023];

// Active high unless specified otherwise
reg        IorD; // mux determines whether PC or ALUout provides address to memory unit
reg        RegWrite; // The general-purpose register selected by the Write register number is
					 // written with the value of the Write data input. 

reg        MemRead;
reg        MemWrite;
reg        MemtoReg;
reg        ALUSrcA; // 0: 1st ALU operand is the PC  1: first ALU operand is from register A
reg [1:0]  ALUSrcB; // 00: 2nd ALU input is register B
                    // 01: 2nd ALU input is the constant 4
					// 10: 2nd ALU input is the immediate generated from the IR

reg        IRWrite; // the output of the memory it written to the IR
reg        PCWrite; // PC is written; the soure is controlled by PCSource
reg        PCWriteCond; // PC is written is the zero output from the ALU is also active

reg [1:0]  ALUop; // 00: ALU add
				  // 01: ALU subtract
				  // 10: funct field of instruction determines ALU op

/////////////////// IRNORE FOR NOW, not doing branch instructions yet
reg [1:0]  PCSource; // 00: output of the ALU (PC+4) is sent to PC for writing
					// 01: the contents of ALUout(the branch target address) are sent to PC for writing
					// 10: the jump target(IR[25:0]<<2 and concatenated with PC+4[31:28] is sent to PC for writing)
////////////////// initialize to 00 for now
////////////////// END IGNORE //////////////////////

wire [31:0] Ain, Bin;
wire [4:0]  IFIDrs1, IFIDrs2; // access rs1 and rs2 field
wire [4:0]  rd; // access rd field of instruction
wire [6:0]  op; // access opcode
////////////////////// END Internal registers ////////////////////////

// define fields from the instruction register
assign IFIDrs1 = IR[19:15];
assign IFIDrs2 = IR[24:20];
assign op      = IR[6:0];
assign rd      = IR[11:7];

// Inputs to the ALU come direcrtly from instruction register
assign Ain = A;
assign Bin = B;

integer i;
initial begin
	PC = 0;
	IR = NOP;
    for (i = 0; i <= 31; i = i + 1) Regs[i] = i; // initialize register file to avoid don't cares
end

always @(posedge clk) begin
	IR <= Memory
endmodule
