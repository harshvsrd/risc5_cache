module alu_decoder (
    input  logic [1:0] alu_op,
    input  logic [2:0] funct3,
    input  logic       funct7_5, // Bit 30 of instruction
    input  logic       is_rtype, // Bit 5 of opcode
    output logic [3:0] alu_ctrl
);
    always_comb begin
        case (alu_op)
            2'b00: alu_ctrl = 4'b0000; // Load/Store/LUI/AUIPC -> ADD
            2'b01: alu_ctrl = 4'b0001; // Branch -> SUB
            2'b10: begin               // R-type or I-type ALU
                case (funct3)
                    3'b000: alu_ctrl = (is_rtype && funct7_5) ? 4'b0001 : 4'b0000; // SUB vs ADD
                    3'b001: alu_ctrl = 4'b0010; // SLL
                    3'b010: alu_ctrl = 4'b0011; // SLT
                    3'b011: alu_ctrl = 4'b0100; // SLTU
                    3'b100: alu_ctrl = 4'b0101; // XOR
                    3'b101: alu_ctrl = funct7_5 ? 4'b0111 : 4'b0110;               // SRA vs SRL
                    3'b110: alu_ctrl = 4'b1000; // OR
                    3'b111: alu_ctrl = 4'b1001; // AND
                endcase
            end
            default: alu_ctrl = 4'b0000;
        endcase
    end
endmodule