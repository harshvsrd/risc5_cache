module wb_stage (
    // Inputs from MEM/WB Pipeline Register
    input  logic [31:0] mem_wb_pc_plus_4,
    input  logic [31:0] mem_wb_alu_out,
    input  logic [31:0] mem_wb_read_data,
    input  logic [4:0]  mem_wb_rd,
    input  wb_ctrl_t    mem_wb_wb,
    
    // Outputs routed back to Register File and Forwarding Unit
    output logic        wb_reg_write,
    output logic [4:0]  wb_rd,
    output logic [31:0] wb_data
);

    assign wb_reg_write = mem_wb_wb.reg_write;
    assign wb_rd        = mem_wb_rd;

    // Multiplexer controlled by result_src
    always_comb begin
        case (mem_wb_wb.result_src)
            2'b00:   wb_data = mem_wb_alu_out;   // R-type, I-type ALU, LUI, AUIPC
            2'b01:   wb_data = mem_wb_read_data; // Loads (LW, LH, LB, LHU, LBU)
            2'b10:   wb_data = mem_wb_pc_plus_4; // Jumps (JAL, JALR)
            default: wb_data = mem_wb_alu_out;
        endcase
    end

endmodule