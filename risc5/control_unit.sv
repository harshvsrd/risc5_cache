module control_unit (
    input  logic [6:0] opcode,
    output logic [1:0] alu_op,
    output logic [1:0] alu_src_a,
    output logic       alu_src_b,
    output logic       branch,
    output logic       jump,
    output logic       mem_read,
    output logic       mem_write,
    output logic       reg_write,
    output logic [1:0] result_src
);
    always_comb begin
        // Default assignments prevent inferred latches
        alu_op     = 2'b00;
        alu_src_a  = 2'b00; 
        alu_src_b  = 0;     
        branch     = 0;
        jump       = 0;
        mem_read   = 0;
        mem_write  = 0;
        reg_write  = 0;
        result_src = 2'b00; 

        case (opcode)
            7'b0110011: begin // R-type
                reg_write = 1;
                alu_op    = 2'b10;
            end
            7'b0010011: begin // I-type ALU
                reg_write = 1;
                alu_src_b = 1;
                alu_op    = 2'b10;
            end
            7'b0000011: begin // Load
                reg_write  = 1;
                result_src = 2'b01; 
                mem_read   = 1;
                alu_src_b  = 1;     
            end
            7'b0100011: begin // Store
                mem_write = 1;
                alu_src_b = 1;
            end
            7'b1100011: begin // Branch
                branch = 1;
                alu_op = 2'b01; 
            end
            7'b0110111: begin // LUI
                reg_write = 1;
                alu_src_a = 2'b10; // Bypass rs1, inject 0
                alu_src_b = 1;     // Add imm to 0
            end
            7'b0010111: begin // AUIPC
                reg_write = 1;
                alu_src_a = 2'b01; // Inject PC
                alu_src_b = 1;     // Add imm to PC
            end
            7'b1101111: begin // JAL
                reg_write  = 1;
                result_src = 2'b10; // Save PC+4
                jump       = 1;
            end
            7'b1100111: begin // JALR
                reg_write  = 1;
                result_src = 2'b10; 
                jump       = 1;
                alu_src_b  = 1;     
            end
        endcase
    end
endmodule