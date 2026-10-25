module forwarding_unit (
    input  logic [4:0] id_ex_rs1,
    input  logic [4:0] id_ex_rs2,
    
    // Signals from EX/MEM Pipeline Register (Instruction 1 step ahead)
    input  logic [4:0] ex_mem_rd,
    input  logic       ex_mem_reg_write,
    
    // Signals from MEM/WB Pipeline Register (Instruction 2 steps ahead)
    input  logic [4:0] mem_wb_rd,
    input  logic       mem_wb_reg_write,
    
    // Output multiplexer controls to the EX Stage
    output logic [1:0] forward_a,
    output logic [1:0] forward_b
);

    always_comb begin
        // Default: No forwarding (use standard ID/EX register data)
        forward_a = 2'b00;
        forward_b = 2'b00;

        // 1. EX/MEM Hazard (Most recent instruction priority)
        if (ex_mem_reg_write && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs1)) begin
            forward_a = 2'b10;
        end
        // 2. MEM/WB Hazard (Second most recent instruction)
        // Evaluates only if the EX/MEM stage is NOT already forwarding to the SAME register
        else if (mem_wb_reg_write && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs1)) begin
            forward_a = 2'b01;
        end

        // Exact same priority hierarchy applied to rs2
        if (ex_mem_reg_write && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs2)) begin
            forward_b = 2'b10;
        end
        else if (mem_wb_reg_write && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs2)) begin
            forward_b = 2'b01;
        end
    end

endmodule