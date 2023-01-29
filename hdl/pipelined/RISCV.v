// Pipelined version with no branch instructions or hazard detection

module RISCVCPU(clk);

localparam LW = 7'b000_0011;
localparam SW = 7'b010_0011;
localparam BEQ = 7'b110_0011;
localparam NOP = 32'h0000_0013;
localparam ALUop = 7'b001_0011;

////////////////////// INPUTS /////////////////////////
input clk;
///////////////////// END OF INPUTS ///////////////////


////////////// REGISTERS AND WIRES ////////////////////
reg [31:0] PC;
reg [0:31] Regs;
reg IDEXA, IDEXB;
reg EXMEMB, EXMEMALUOut;
reg MEMWBValue;

reg [31:0] IMemory[0:1023], DMemory[0:1023]; // separate memories for instructions and data
reg [31:0] IFIDIR, IDEXIR, EXMEMIR, MEMWBIR; // pipeline registers

wire [4:0] IFIDrs1, IFIDrs2, MEMWBrd; // Access register fields
wire [6:0] IDEXop, EXMEMop, MEMWBop; // Access opcodes
wire [31:0] Ain, Bin; // ALU inputs
/////////////////END OF REGISTERS AND WIRES ////////////////


///////////// Assignments define fields from the pipeline registers
assign IFIDrs1  = IFIDIR[19:15];  // rs1 field
assign IFIDrs2  = IFIDIR[24:20];  // rs2 field
assign IDEXop   = IDEXIR[6:0];    // the opcode
assign EXMEMop  = EXMEMIR[6:0];   // the opcode
assign MEMWBop  = MEMWBIR[6:0];   // the opcode
assign MEMWBrd  = MEMWBIR[11:7];  // rd field

// Inputs to the ALU come directly from the ID/EX pipeline registers
assign Ain = IDEXA;
assign Bin = IDEXB;

////////////// END Assignments ////////////////////////


integer i; // used to initialize registers
initial begin
    PC = 0;
    IFIDIR = NOP;
    IDEXIR = NOP;
    EXMEMIR = NOP;
    MEMWBIR = NOP; // put NOPs in pipeline registers
    for (i = 0;i <= 31;i = i+1) Regs[i] = i; // initialize registers--just so they aren't x'cares
end


///////////////////////////////////////////// PROCESSING ////////////////////////////////////////////////
always @(posedge clk) begin
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
        EXMEMALUOut <= IDEXA + {{53[IDEXIR[31]]}, IDEXIR[30:20]};
    end else if (IDEXop == SW)
        EXMEMALUOut <= IDEXA + {{53[IDEXIR[31]]}, IDEXIR[30:25], IDEXIR[11:7]};
    end else if (IDEXop == ALUop) begin
        case (IDEXIR[31:25]) // for different R-type instructions
            0: EXMEMALUOut <= Ain + Bin;
            /*
            *
            * ADD OTHER INSTRUCTIONS
            *
            *
            */
            default: 
        endcase
    end
    /////////////////////////// END EX Stage /////////////////////////

    EXMEMIR <= IDEXIR; // Pass along the IR
    EXMEMB <= IDEXB; // & B register


    ////////////////////////////// MEM Stage ///////////////////////////////
    if (EXMEMop == ALUop) MEMWBValue <= EXMEMALUOut;
    else if (EXMEMop == LW) MEMWBValue <= DMemory[EXMEMALUOut >> 2];
    else if (EXMEMop == SW) DMemory[EXMEMALUOut >> 2] <= EXMEMB;
    ///////////////////////////// END MEM Stage //////////////////////////////

    MEMWBIR <= EXMEMIR; // Pass along IR


    ////////////////////////////// WB Stage /////////////////////////////////
    // update registers if load/ALU op and destination not 0
    if (((MEMWBop == LW) || (MEMWBop == ALUop)) && (MEMWBrd != 0)) begin
        Regs[MEMWBrd] <= MEMWBvalue;
    end
    /////////////////////////////// END WB Stage /////////////////////////////
end
///////////////////////////////////// END PROCESSING ////////////////////////////////////////

endmodule
