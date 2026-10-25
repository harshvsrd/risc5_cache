
module if_stage (
    input  logic        clk,
    input  logic        reset,
    
    // Control signals from Hazard Detection Unit
    input  logic        stall_if,
    input  logic        flush_if,
    
    // Branch/Jump control from Execute (EX) stage
    input  logic        pc_src,
    input  logic [31:0] pc_branch,
    
    // Pipeline Register Outputs to Decode (ID) stage
    output logic [31:0] if_id_pc,
    output logic [31:0] if_id_instr
);

    logic [31:0] pc_reg;
    logic [31:0] pc_next;
    logic [31:0] pc_plus_4;
    logic [31:0] instr_mem_out;

    // Next PC Logic: Select between sequential execution and branch/jump target
    assign pc_plus_4 = pc_reg + 32'd4;
    assign pc_next   = pc_src ? pc_branch : pc_plus_4;

    // Program Counter (PC) Register
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            pc_reg <= 32'd0;
        else if (!stall_if)
            pc_reg <= pc_next;
    end

    // Instruction Memory Instantiation
    instr_mem imem (
        .addr(pc_reg),
        .instr(instr_mem_out)
    );

    // IF/ID Pipeline Register
    always_ff @(posedge clk or posedge reset) begin
        if (reset || flush_if) begin
            if_id_pc    <= 32'd0;
            if_id_instr <= 32'h00000013; // Canonical NOP
        end
        else if (!stall_if) begin
            if_id_pc    <= pc_reg;
            if_id_instr <= instr_mem_out;
        end
    end

endmodule