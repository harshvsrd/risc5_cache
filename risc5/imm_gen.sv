module imm_gen (
    input  logic [31:0] instr,
    output logic [31:0] imm_out
);
    logic [6:0] opcode;
    assign opcode = instr[6:0];

    // Replaced always_comb with always @(*) to bypass Icarus Verilog bug
    always @(*) begin
        case (opcode)
            // I-Type
            7'b0000011, 7'b1100111, 7'b0010011: 
                imm_out = {{20{instr[31]}}, instr[31:20]};
                
            // S-Type
            7'b0100011: 
                imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};
                
            // B-Type
            7'b1100011: 
                imm_out = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
                
            // U-Type
            7'b0110111, 7'b0010111: 
                imm_out = {instr[31:12], 12'b0};
                
            // J-Type
            7'b1101111: 
                imm_out = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
                
            default: 
                imm_out = 32'd0;
        endcase
    end
endmodule