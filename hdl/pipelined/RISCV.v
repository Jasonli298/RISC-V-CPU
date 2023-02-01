// Pipelined version with no branch instructions or hazard detection

module RISCVCPU(clk);

localparam LW    = 7'b000_0011;
localparam SW    = 7'b010_0011;
localparam BEQ   = 7'b110_0011;
localparam NOP   = 32'h0000_0013;
localparam ALUop = 7'b011_0011;

////////////////////// INPUTS /////////////////////////
input clk;
///////////////////// END OF INPUTS ///////////////////


////////////// REGISTERS AND WIRES ////////////////////
reg [31:0] PC;
reg [0:31] Regs;
reg [31:0] IDEXA, IDEXB;
reg [31:0] EXMEMB, EXMEMALUout;
reg [31:0] MEMWBValue;

reg [31:0] IMemory[0:1023], DMemory[0:1023]; // separate memories for instructions and data
reg [31:0] IFIDIR, IDEXIR, EXMEMIR, MEMWBIR; // pipeline registers

wire [4:0] IFIDrs1, IFIDrs2, MEMWBrd; // Access register fields
wire [6:0] IDEXop, EXMEMop, MEMWBop; // Access opcodes
wire [31:0] Ain, Bin; // ALU inputs
// Bypass signals
wire bypassAfromMEM, bypassAfromALUinWB,
	 bypassBfromMEM, bypassBfromALUinWB,
	 bypassAfromLDinWB, bypassBfromLDinWB;
wire stall;
/////////////////END OF REGISTERS AND WIRES ////////////////


///////////// Assignments define fields from the pipeline registers
assign IFIDrs1 = IFIDIR[19:15]; // rs1 field
assign IFIDrs2 = IFIDIR[24:20]; // rs2 field
assign IDEXrs1  = IDEXIR[19:15];
assign IDEXrs2  = IDEXIR[24:20];
assign IDEXop  = IDEXIR[6:0];   // the opcode
assign EXMEMop = EXMEMIR[6:0];  // the opcode
assign EXMEMrd = EXMEMIR[11:7]; // the read address
assign MEMWBop = MEMWBIR[6:0];  // the opcode
assign MEMWBrd = MEMWBIR[11:7]; // rd field

// Bypass to iunput A from the MEM stage for an ALU operation
assign bypassAfromMEM = (IDEXrs1 == EXMEMrd) && (IDEXrs1 != 0) && (EXMEMop == ALUop);
// Bypass to input  B from the MEM stage for an ALU op

assign bypassBfromMEM = (IDEXrs2 == EXMEMrd) && (IDEXrs2 != 0) && (EXMEMop == ALUop);
assign bypassAfromALUinWB = (IDEXrs1 == MEMWBrd) && (IDEXrs1 != 0) && (MEMWBop == ALUop);
assign bypassBfromALUinWB = (IDEXrs2 == MEMWBrd) && (IDEXrs2 != 0) && (MEMWBop == ALUop);
assign bypassAfromLDinWB = (IDEXrs1 == MEMWBrd) && (IDEXrs1 != 0) && (EXMEMop == LW);
assign bypassBfromLDinWB = (IDEXrs2 == MEMWBrd) && (IDEXrs2 != 0) && (EXMEMop == LW);
assign Ain = bypassAfromMEM ? EXMEMALUout : (bypassAfromALUinWB || bypassAfromLDinWB) ? MEMWBValue : IDEXA;
assign Bin = bypassBfromMEM ? EXMEMALUout : (bypassBfromALUinWB || bypassBfromLDinWB) ? MEMWBValue : IDEXB;
assign stall = (MEMWBop == LW) && ( // source instruction is a load
			   (((IDEXop == LW) || (IDEXop == SW)) && (IDEXrs1 == MEMWBrd)) || // stall for address calc
			   ((IDEXop == ALUop) && ((IDEXrs1 == MEMWBrd) ||(IDEXrs2 == MEMWBrd)))); // ALU use

integer i; // used to initialize registers
initial begin
    PC = 0;
    IFIDIR = NOP;
    IDEXIR = NOP;
    EXMEMIR = NOP;
    MEMWBIR = NOP; // put NOPs in pipeline registers
    for (i = 0;i <= 31;i = i+1) Regs[i] = i; // initialize registers--just so they aren't x'cares
	$readmemb("IMemory.txt", IMemory);
	$readmemb("DMemory.txt", DMemory);
end


///////////////////////////////////////////// PROCESSING ////////////////////////////////////////////////
always @(posedge clk) begin
	if (~stall) begin
    // Fetch 1st instruction and increment PC
        IFIDIR <= IMemory[PC >> 2];
        PC <= PC + 4;

        // 2nd instruction in pipeline fetches registers
        IDEXA <= Regs[IFIDrs1]; // Get the two
        IDEXB <= Regs[IFIDrs2]; // registers

        IDEXIR <= IFIDIR; // Pass along IR -- can happen anywhere since only affects next stage

        ///////////////////////////// EX Stage /////////////////////////
        // 3rd instruction doing address calculation for ALU op
        if (IDEXop == LW) begin
            EXMEMALUout <= IDEXA + IDEXIR[31:20];
        end else if (IDEXop == SW) begin
            EXMEMALUout <= IDEXA + {IDEXIR[31:25], IDEXIR[11:7]};
        end else if (IDEXop == ALUop) begin
            case (IDEXIR[31:25]) // for different R-type instructions
                7'b0000000: EXMEMALUout <= Ain + Bin; // add operation
				7'b0100000: EXMEMALUout <= Ain - Bin;

                /*
                *
                * ADD OTHER INSTRUCTIONS
                *
                *
                */
                default: EXMEMALUout <= 32'b0;
            endcase
			EXMEMIR <= IDEXIR; // Pass along the IR
        	EXMEMB <= IDEXB; // & B register
		end
	end // end if (~stall) begin
	else EXMEMIR <= NOP;
	/////////////////////////// END EX Stage /////////////////////////

	////////////////////////////// MEM Stage ///////////////////////////////
	if      (EXMEMop == ALUop) MEMWBValue              <= EXMEMALUout;
	else if (EXMEMop == LW)    MEMWBValue              <= DMemory[EXMEMALUout >> 2];
	else if (EXMEMop == SW)    DMemory[EXMEMALUout>>2] <= EXMEMB;
	///////////////////////////// END MEM Stage //////////////////////////////

	MEMWBIR <= EXMEMIR; // Pass along IR

	////////////////////////////// WB Stage /////////////////////////////////
	// update registers if load/ALU op and destination not 0
	if (((MEMWBop == LW) || (MEMWBop == ALUop)) && (MEMWBrd != 0)) begin
		Regs[MEMWBrd] <= MEMWBValue;
	end
    /////////////////////////////// END WB Stage /////////////////////////////
end
///////////////////////////////////// END PROCESSING ////////////////////////////////////////

endmodule
