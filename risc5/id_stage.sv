module id_stage (
    input  logic        clk,
    input  logic        reset,
    
    input  logic [31:0] if_id_pc,
    input  logic [31:0] if_id_instr,
    
    input  logic        wb_reg_write_en,
    input  logic [4:0]  wb_rd,
    input  logic [31:0] wb_data,
    
    input  logic        flush_id,
    
    output logic [31:0] id_ex_pc,
    output logic [31:0] id_ex_rs1_data,
    output logic [31:0] id_ex_rs2_data,
    output logic [31:0] id_ex_imm,
    output logic [4:0]  id_ex_rs1,
    output logic [4:0]  id_ex_rs2,
    output logic [4:0]  id_ex_rd,
    output logic [2:0]  id_ex_funct3,
    output ex_ctrl_t    id_ex_ex,
    output mem_ctrl_t   id_ex_mem,
    output wb_ctrl_t    id_ex_wb
);

    // Internal wires
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [31:0] imm_out;
    
    wb_ctrl_t   wb_ctrl_next;
    mem_ctrl_t  mem_ctrl_next;
    ex_ctrl_t   ex_ctrl_next;
    logic [1:0] alu_op;

    // Sub-module Instantiations
    reg_file rf (
        .clk(clk),
        .we(wb_reg_write_en),
        .rs1(if_id_instr[19:15]),
        .rs2(if_id_instr[24:20]),
        .rd(wb_rd),
        .wd(wb_data),
        .rd1(rs1_data),
        .rd2(rs2_data)
    );

    imm_gen ig (
        .instr(if_id_instr),
        .imm_out(imm_out)
    );

    control_unit cu (
        .opcode    (if_id_instr[6:0]),
        .alu_op    (alu_op),
        .alu_src_a (ex_ctrl_next.alu_src_a),
        .alu_src_b (ex_ctrl_next.alu_src_b),
        .branch    (ex_ctrl_next.branch),
        .jump      (ex_ctrl_next.jump),
        .mem_read  (mem_ctrl_next.mem_read),
        .mem_write (mem_ctrl_next.mem_write),
        .reg_write (wb_ctrl_next.reg_write),
        .result_src(wb_ctrl_next.result_src)
    );

    alu_decoder ad (
        .alu_op    (alu_op),
        .funct3    (if_id_instr[14:12]),
        .funct7_5  (if_id_instr[30]),
        .is_rtype  (if_id_instr[5]),
        .alu_ctrl  (ex_ctrl_next.alu_ctrl)
    );

    // ID/EX Pipeline Register
    always_ff @(posedge clk or posedge reset) begin
        if (reset || flush_id) begin
            id_ex_pc       <= 32'd0;
            id_ex_rs1_data <= 32'd0;
            id_ex_rs2_data <= 32'd0;
            id_ex_imm      <= 32'd0;
            id_ex_rs1      <= 5'd0;
            id_ex_rs2      <= 5'd0;
            id_ex_rd       <= 5'd0;
            id_ex_funct3   <= 3'd0;
            id_ex_wb       <= '0;
            id_ex_mem      <= '0;
            id_ex_ex       <= '0;
        end else begin
            id_ex_pc       <= if_id_pc;
            id_ex_rs1_data <= rs1_data;
            id_ex_rs2_data <= rs2_data;
            id_ex_imm      <= imm_out;
            id_ex_rs1      <= if_id_instr[19:15];
            id_ex_rs2      <= if_id_instr[24:20];
            id_ex_rd       <= if_id_instr[11:7];
            id_ex_funct3   <= if_id_instr[14:12];
            id_ex_wb       <= wb_ctrl_next;
            id_ex_mem      <= mem_ctrl_next;
            id_ex_ex       <= ex_ctrl_next;
        end
    end
endmodule