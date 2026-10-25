module hazard_unit (
    // Instruction Decode (ID) stage source registers
    input  logic [4:0] if_id_rs1,
    input  logic [4:0] if_id_rs2,
    
    // Execution (EX) stage destination register and memory read flag
    input  logic [4:0] id_ex_rd,
    input  logic       id_ex_mem_read,
    
    // Branch/Jump taken flag from EX stage
    input  logic       pc_src,
    
    // Hazard control outputs
    output logic       stall_if,
    output logic       flush_if,
    output logic       flush_id
);

    logic load_use_hazard;

    always_comb begin
        // 1. Detect Load-Use Hazard
        // Triggers if a load in EX targets a register currently needed by the instruction in ID
        if (id_ex_mem_read && (id_ex_rd != 5'd0) && 
           ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2))) begin
            load_use_hazard = 1'b1;
        end else begin
            load_use_hazard = 1'b0;
        end

        // 2. Route Stalls and Flushes
        stall_if = 1'b0;
        flush_if = 1'b0;
        flush_id = 1'b0;

        if (pc_src) begin
            // Control Hazard: Branch or Jump taken in EX
            // Squash the two wrong-path instructions currently in IF and ID
            flush_if = 1'b1;
            flush_id = 1'b1;
        end else if (load_use_hazard) begin
            // Data Hazard: Load-Use
            // Freeze PC and IF/ID to keep the dependent instruction in the decode stage
            stall_if = 1'b1;
            // Inject a NOP into EX to stall execution for one cycle
            flush_id = 1'b1;
        end
    end

endmodule