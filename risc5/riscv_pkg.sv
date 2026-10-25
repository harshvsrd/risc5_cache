typedef struct packed {
    logic       reg_write;
    logic [1:0] result_src; // 00: ALU Out, 01: Mem Data, 10: PC + 4
} wb_ctrl_t;

typedef struct packed {
    logic       mem_read;
    logic       mem_write;
} mem_ctrl_t;

typedef struct packed {
    logic [1:0] alu_src_a;  // 00: rs1, 01: PC, 10: Zero
    logic       alu_src_b;  // 0: rs2, 1: immediate
    logic [3:0] alu_ctrl;   // 4-bit command for the ALU
    logic       branch;
    logic       jump;
} ex_ctrl_t;