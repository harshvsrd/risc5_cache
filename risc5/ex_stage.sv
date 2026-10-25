

module ex_stage (
    input  logic        clk,
    input  logic        reset,
    
    // Pipeline inputs from ID/EX
    input  logic [31:0] id_ex_pc,
    input  logic [31:0] id_ex_rs1_data,
    input  logic [31:0] id_ex_rs2_data,
    input  logic [31:0] id_ex_imm,
    input  logic [4:0]  id_ex_rs1,
    input  logic [4:0]  id_ex_rs2,
    input  logic [4:0]  id_ex_rd,
    input  logic [2:0]  id_ex_funct3,  // Needed for branch logic and memory widths
    
    // Control structs from ID/EX
    input  ex_ctrl_t    id_ex_ex,
    input  mem_ctrl_t   id_ex_mem,
    input  wb_ctrl_t    id_ex_wb,

    // Forwarding controls & data from Hazard/Forwarding Unit
    input  logic [1:0]  forward_a,
    input  logic [1:0]  forward_b,
    input  logic [31:0] ex_mem_alu_out_fwd, // Bypassed from EX/MEM
    input  logic [31:0] wb_data_fwd,        // Bypassed from MEM/WB
    
    // Outputs back to IF Stage
    output logic        pc_src,
    output logic [31:0] pc_branch,
    
    // Outputs to EX/MEM Pipeline Register
    output logic [31:0] ex_mem_pc_plus_4,
    output logic [31:0] ex_mem_alu_out,
    output logic [31:0] ex_mem_write_data,
    output logic [4:0]  ex_mem_rd,
    output logic [2:0]  ex_mem_funct3,
    output mem_ctrl_t   ex_mem_mem,
    output wb_ctrl_t    ex_mem_wb
);

    logic [31:0] forwarded_a;
    logic [31:0] forwarded_b;
    logic [31:0] alu_in_a;
    logic [31:0] alu_in_b;
    logic [31:0] alu_result;
    logic        alu_zero;
    logic        branch_cond_met;

    // 1. Forwarding Multiplexers (Solves Read-After-Write hazards)
    always_comb begin
        case (forward_a)
            2'b00: forwarded_a = id_ex_rs1_data;
            2'b01: forwarded_a = wb_data_fwd;
            2'b10: forwarded_a = ex_mem_alu_out_fwd;
            default: forwarded_a = id_ex_rs1_data;
        endcase
    end

    always_comb begin
        case (forward_b)
            2'b00: forwarded_b = id_ex_rs2_data;
            2'b01: forwarded_b = wb_data_fwd;
            2'b10: forwarded_b = ex_mem_alu_out_fwd;
            default: forwarded_b = id_ex_rs2_data;
        endcase
    end

    // 2. ALU Source Multiplexers
    always_comb begin
        case (id_ex_ex.alu_src_a)
            2'b00: alu_in_a = forwarded_a;
            2'b01: alu_in_a = id_ex_pc;
            2'b10: alu_in_a = 32'd0;
            default: alu_in_a = forwarded_a;
        endcase
    end

    assign alu_in_b = id_ex_ex.alu_src_b ? id_ex_imm : forwarded_b;

    // 3. ALU Instantiation
    alu u_alu (
        .a           (alu_in_a),
        .b           (alu_in_b),
        .alu_control (id_ex_ex.alu_ctrl),
        .alu_out     (alu_result),
        .zero        (alu_zero)
    );

    // 4. Branch Evaluation Logic
    always_comb begin
        case (id_ex_funct3)
            3'b000: branch_cond_met = (forwarded_a == forwarded_b);                   // BEQ
            3'b001: branch_cond_met = (forwarded_a != forwarded_b);                   // BNE
            3'b100: branch_cond_met = ($signed(forwarded_a) < $signed(forwarded_b));  // BLT
            3'b101: branch_cond_met = ($signed(forwarded_a) >= $signed(forwarded_b)); // BGE
            3'b110: branch_cond_met = (forwarded_a < forwarded_b);                    // BLTU
            3'b111: branch_cond_met = (forwarded_a >= forwarded_b);                   // BGEU
            default: branch_cond_met = 1'b0;
        endcase
    end

    // 5. Target Calculation & IF Stage Routing
    // JALR clears the lowest bit of the (rs1 + imm) sum. JAL and Branches use PC + imm.
    assign pc_branch = (id_ex_ex.jump && id_ex_ex.alu_src_a == 2'b00) ? 
                       (alu_result & ~32'd1) : (id_ex_pc + id_ex_imm);
                       
    assign pc_src = id_ex_ex.jump | (id_ex_ex.branch & branch_cond_met);

    // 6. EX/MEM Pipeline Register
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            ex_mem_pc_plus_4  <= 32'd0;
            ex_mem_alu_out    <= 32'd0;
            ex_mem_write_data <= 32'd0;
            ex_mem_rd         <= 5'd0;
            ex_mem_funct3     <= 3'd0;
            ex_mem_mem        <= '0;
            ex_mem_wb         <= '0;
        end else begin
            ex_mem_pc_plus_4  <= id_ex_pc + 32'd4;
            ex_mem_alu_out    <= alu_result;
            ex_mem_write_data <= forwarded_b; // Crucial: Store data is the forwarded rs2!
            ex_mem_rd         <= id_ex_rd;
            ex_mem_funct3     <= id_ex_funct3;
            ex_mem_mem        <= id_ex_mem;
            ex_mem_wb         <= id_ex_wb;
        end
    end

endmodule