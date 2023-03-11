module Datapath
    (ALUop,
     MemtoReg,
     MemRead,
     MemWrite,
     IorD,
     RegWrite,
     IRWrite,
     PCWrite,
     PCWriteCond,
     ALUSrcA,
     ALUSrcB,
     PCSource,
     opcode,
     clk);
    
    localparam LW = 7'b000_0011,
               SW = 7'b010_0011;
    
    input [1:0] ALUop, ALUSrcB;
    input MemtoReg, MemRead, MemWrite, IorD, RegWrite, IRWrite, PCWrite,
          PCWriteCond, ALUSrcA, PCSource, clk;
    
    output [6:0] opcode; // opcode is needed as an output by control
    reg [31:0] PC, MDR, ALUOut; // CPU state and some temporaries

    reg [31:0] Memory[0:1023];
    reg [31:0] IR;
    
    wire [31:0] A;
    wire [31:0] SignExtendOffset;
    wire [31:0] ALUResultOut;
    wire [31:0] PCValue;
    wire [31:0] Writedata;
    wire [31:0] ALUAin;
    wire [31:0] ALUBin;
    wire [6:0] opcode;
    wire signed [31:0] PCOffset;
    wire signed [31:0] MemOut;
    wire [3:0] ALUCtl;
    wire Zero;

    // Reading using address with either ALUOut or PC as the address source
    assign MemOut = MemRead ? Memory[(IorD ? ALUOut : PC) >> 2] : 0;
    assign opcode = IR[6:0]; // lower 7 bits of instruction
    assign funct7 = IR[31:25];
    assign Writedata = MemtoReg ? MDR : ALUOut;

    assign ImmGen = (opcode == LW) ? IR[31:20] : 
               /* (opcode == SW) */ {IR[31:25], IR[11:7]};
    assign PCOffset = PCOffset = {{22{IR[31]}}, IR[7], IR[30:25], IR[11:8], 1'b0};
    assign ALUAin = ALUSrcA ? A : PC; // ALU input is PC or A

    ALUControl alucontroller(.ALUOp(ALUop), .FuncCode(funct7), ALUCtl);

    assign PCValue = PCSource ? ALUOut : ALUResultOut;

    Mul4to1 ALUBinput(.In1(B), 
                      .In2(32'd4), 
                      .In3(ImmGen), 
                      .In4(PCOffset), 
                      .Sel(ALUSrcB), 
                      .Out(ALUBin));

    RISCVALU ALU(.ALUctl(ALUCtl), 
                 .A(ALUAin), 
                 .B(ALUBin), 
                 .ALUOut(ALUR), 
                 .Zero(Zero));

    always @(posedge clk) begin
        if (MemWrite) begin
            Memory[ALUOut >> 2] <= B;
        end
        ALUOut <= ALUResultOut;
        if (IRWrite) begin
            IR <= MemOut;
        end
        MDR <= MemOut;
    end
    
endmodule
