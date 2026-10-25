// 1. Data Structures MUST be included first
`include "riscv_pkg.sv"

// 2. Base Components
`include "alu.sv"
`include "reg_file.sv"
`include "imm_gen.sv"
`include "control_unit.sv"
`include "alu_decoder.sv"
`include "instr_mem.sv"
`include "data_mem.sv"

// 3. Traffic Controllers
`include "hazard_unit.sv"
`include "forwarding_unit.sv"

// 4. The 5 Pipeline Stages
`include "if_stage.sv"
`include "id_stage.sv"
`include "ex_stage.sv"
`include "mem_stage.sv"
`include "wb_stage.sv"

// 5. The Top-Level Wrapper
module rv32i_core (
    input logic clk,
    input logic reset
);

    // Hazard & Forwarding Controls
    logic        stall_if;
    logic        flush_if;
    logic        flush_id;
    logic [1:0]  forward_a;
    logic [1:0]  forward_b;

    // IF/ID Pipeline Register Signals
    logic [31:0] if_id_pc;
    logic [31:0] if_id_instr;

    // ID/EX Pipeline Register Signals
    logic [31:0] id_ex_pc;
    logic [31:0] id_ex_rs1_data;
    logic [31:0] id_ex_rs2_data;
    logic [31:0] id_ex_imm;
    logic [4:0]  id_ex_rs1;
    logic [4:0]  id_ex_rs2;
    logic [4:0]  id_ex_rd;
    logic [2:0]  id_ex_funct3;
    ex_ctrl_t    id_ex_ex;
    mem_ctrl_t   id_ex_mem;
    wb_ctrl_t    id_ex_wb;

    // EX/MEM Pipeline Register Signals
    logic        pc_src;
    logic [31:0] pc_branch;
    logic [31:0] ex_mem_pc_plus_4;
    logic [31:0] ex_mem_alu_out;
    logic [31:0] ex_mem_write_data;
    logic [4:0]  ex_mem_rd;
    logic [2:0]  ex_mem_funct3;
    mem_ctrl_t   ex_mem_mem;
    wb_ctrl_t    ex_mem_wb;

    // MEM/WB Pipeline Register Signals
    logic [31:0] mem_wb_pc_plus_4;
    logic [31:0] mem_wb_alu_out;
    logic [31:0] mem_wb_read_data;
    logic [4:0]  mem_wb_rd;
    wb_ctrl_t    mem_wb_wb;

    // Writeback Signals
    logic        wb_reg_write;
    logic [4:0]  wb_rd;
    logic [31:0] wb_data;

    // Module Instantiations
    if_stage u_if_stage (
        .clk        (clk),
        .reset      (reset),
        .stall_if   (stall_if),
        .flush_if   (flush_if),
        .pc_src     (pc_src),
        .pc_branch  (pc_branch),
        .if_id_pc   (if_id_pc),
        .if_id_instr(if_id_instr)
    );

    id_stage u_id_stage (
        .clk            (clk),
        .reset          (reset),
        .if_id_pc       (if_id_pc),
        .if_id_instr    (if_id_instr),
        .wb_reg_write_en(wb_reg_write),
        .wb_rd          (wb_rd),
        .wb_data        (wb_data),
        .flush_id       (flush_id),
        .id_ex_pc       (id_ex_pc),
        .id_ex_rs1_data (id_ex_rs1_data),
        .id_ex_rs2_data (id_ex_rs2_data),
        .id_ex_imm      (id_ex_imm),
        .id_ex_rs1      (id_ex_rs1),
        .id_ex_rs2      (id_ex_rs2),
        .id_ex_rd       (id_ex_rd),
        .id_ex_funct3   (id_ex_funct3),
        .id_ex_ex       (id_ex_ex),
        .id_ex_mem      (id_ex_mem),
        .id_ex_wb       (id_ex_wb)
    );

    ex_stage u_ex_stage (
        .clk               (clk),
        .reset             (reset),
        .id_ex_pc          (id_ex_pc),
        .id_ex_rs1_data    (id_ex_rs1_data),
        .id_ex_rs2_data    (id_ex_rs2_data),
        .id_ex_imm         (id_ex_imm),
        .id_ex_rs1         (id_ex_rs1),
        .id_ex_rs2         (id_ex_rs2),
        .id_ex_rd          (id_ex_rd),
        .id_ex_funct3      (id_ex_funct3),
        .id_ex_ex          (id_ex_ex),
        .id_ex_mem         (id_ex_mem),
        .id_ex_wb          (id_ex_wb),
        .forward_a         (forward_a),
        .forward_b         (forward_b),
        .ex_mem_alu_out_fwd(ex_mem_alu_out), 
        .wb_data_fwd       (wb_data),        
        .pc_src            (pc_src),
        .pc_branch         (pc_branch),
        .ex_mem_pc_plus_4  (ex_mem_pc_plus_4),
        .ex_mem_alu_out    (ex_mem_alu_out),
        .ex_mem_write_data (ex_mem_write_data),
        .ex_mem_rd         (ex_mem_rd),
        .ex_mem_funct3     (ex_mem_funct3),
        .ex_mem_mem        (ex_mem_mem),
        .ex_mem_wb         (ex_mem_wb)
    );

    mem_stage u_mem_stage (
        .clk              (clk),
        .reset            (reset),
        .ex_mem_pc_plus_4 (ex_mem_pc_plus_4),
        .ex_mem_alu_out   (ex_mem_alu_out),
        .ex_mem_write_data(ex_mem_write_data),
        .ex_mem_rd        (ex_mem_rd),
        .ex_mem_funct3    (ex_mem_funct3),
        .ex_mem_mem       (ex_mem_mem),
        .ex_mem_wb        (ex_mem_wb),
        .mem_wb_pc_plus_4 (mem_wb_pc_plus_4),
        .mem_wb_alu_out   (mem_wb_alu_out),
        .mem_wb_read_data (mem_wb_read_data),
        .mem_wb_rd        (mem_wb_rd),
        .mem_wb_wb        (mem_wb_wb)
    );

    wb_stage u_wb_stage (
        .mem_wb_pc_plus_4 (mem_wb_pc_plus_4),
        .mem_wb_alu_out   (mem_wb_alu_out),
        .mem_wb_read_data (mem_wb_read_data),
        .mem_wb_rd        (mem_wb_rd),
        .mem_wb_wb        (mem_wb_wb),
        .wb_reg_write     (wb_reg_write),
        .wb_rd            (wb_rd),
        .wb_data          (wb_data)
    );

    hazard_unit u_hazard_unit (
        .if_id_rs1      (if_id_instr[19:15]),
        .if_id_rs2      (if_id_instr[24:20]),
        .id_ex_rd       (id_ex_rd),
        .id_ex_mem_read (id_ex_mem.mem_read),
        .pc_src         (pc_src),
        .stall_if       (stall_if),
        .flush_if       (flush_if),
        .flush_id       (flush_id)
    );

    forwarding_unit u_forwarding_unit (
        .id_ex_rs1        (id_ex_rs1),
        .id_ex_rs2        (id_ex_rs2),
        .ex_mem_rd        (ex_mem_rd),
        .ex_mem_reg_write (ex_mem_wb.reg_write),
        .mem_wb_rd        (mem_wb_rd),
        .mem_wb_reg_write (mem_wb_wb.reg_write),
        .forward_a        (forward_a),
        .forward_b        (forward_b)
    );

endmodule