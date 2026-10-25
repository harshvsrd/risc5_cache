

module mem_stage (
    input  logic        clk,
    input  logic        reset,
    
    // Inputs from EX/MEM Pipeline Register
    input  logic [31:0] ex_mem_pc_plus_4,
    input  logic [31:0] ex_mem_alu_out,
    input  logic [31:0] ex_mem_write_data,
    input  logic [4:0]  ex_mem_rd,
    input  logic [2:0]  ex_mem_funct3,
    input  mem_ctrl_t   ex_mem_mem,
    input  wb_ctrl_t    ex_mem_wb,
    
    // Outputs to MEM/WB Pipeline Register
    output logic [31:0] mem_wb_pc_plus_4,
    output logic [31:0] mem_wb_alu_out,
    output logic [31:0] mem_wb_read_data,
    output logic [4:0]  mem_wb_rd,
    output wb_ctrl_t    mem_wb_wb
);

    logic [31:0] raw_mem_data;
    logic [31:0] formatted_read_data;
    logic [31:0] formatted_write_data;
    logic [3:0]  byte_enable;
    logic [1:0]  byte_offset;

    assign byte_offset = ex_mem_alu_out[1:0];

    // 1. Store Formatting: Byte mask and data alignment
    always_comb begin
        byte_enable          = 4'b0000;
        formatted_write_data = 32'd0;

        if (ex_mem_mem.mem_write) begin
            case (ex_mem_funct3)
                3'b000: begin // SB (Store Byte)
                    byte_enable = 4'b0001 << byte_offset;
                    formatted_write_data[byte_offset*8 +: 8] = ex_mem_write_data[7:0];
                end
                3'b001: begin // SH (Store Halfword)
                    byte_enable = byte_offset[1] ? 4'b1100 : 4'b0011;
                    formatted_write_data[byte_offset[1]*16 +: 16] = ex_mem_write_data[15:0];
                end
                3'b010: begin // SW (Store Word)
                    byte_enable          = 4'b1111;
                    formatted_write_data = ex_mem_write_data;
                end
                default: begin
                    byte_enable          = 4'b0000;
                    formatted_write_data = ex_mem_write_data;
                end
            endcase
        end
    end

    // 2. Data Memory Instantiation
    data_mem dmem (
        .clk        (clk),
        .we         (ex_mem_mem.mem_write),
        .byte_en    (byte_enable),
        .addr       (ex_mem_alu_out),
        .write_data (formatted_write_data),
        .read_data  (raw_mem_data)
    );

    // 3. Load Formatting: Sign and Zero Extension
    always_comb begin
        case (ex_mem_funct3)
            3'b000: begin // LB (Load Byte Signed)
                case (byte_offset)
                    2'b00: formatted_read_data = {{24{raw_mem_data[7]}},  raw_mem_data[7:0]};
                    2'b01: formatted_read_data = {{24{raw_mem_data[15]}}, raw_mem_data[15:8]};
                    2'b10: formatted_read_data = {{24{raw_mem_data[23]}}, raw_mem_data[23:16]};
                    2'b11: formatted_read_data = {{24{raw_mem_data[31]}}, raw_mem_data[31:24]};
                endcase
            end
            3'b001: begin // LH (Load Halfword Signed)
                formatted_read_data = byte_offset[1] ? 
                    {{16{raw_mem_data[31]}}, raw_mem_data[31:16]} : 
                    {{16{raw_mem_data[15]}}, raw_mem_data[15:0]};
            end
            3'b010: begin // LW (Load Word)
                formatted_read_data = raw_mem_data;
            end
            3'b100: begin // LBU (Load Byte Unsigned)
                case (byte_offset)
                    2'b00: formatted_read_data = {24'd0, raw_mem_data[7:0]};
                    2'b01: formatted_read_data = {24'd0, raw_mem_data[15:8]};
                    2'b10: formatted_read_data = {24'd0, raw_mem_data[23:16]};
                    2'b11: formatted_read_data = {24'd0, raw_mem_data[31:24]};
                endcase
            end
            3'b101: begin // LHU (Load Halfword Unsigned)
                formatted_read_data = byte_offset[1] ? 
                    {16'd0, raw_mem_data[31:16]} : 
                    {16'd0, raw_mem_data[15:0]};
            end
            default: formatted_read_data = raw_mem_data;
        endcase
    end

    // 4. MEM/WB Pipeline Register
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            mem_wb_pc_plus_4 <= 32'd0;
            mem_wb_alu_out   <= 32'd0;
            mem_wb_read_data <= 32'd0;
            mem_wb_rd        <= 5'd0;
            mem_wb_wb        <= '0;
        end else begin
            mem_wb_pc_plus_4 <= ex_mem_pc_plus_4;
            mem_wb_alu_out   <= ex_mem_alu_out;
            mem_wb_read_data <= formatted_read_data;
            mem_wb_rd        <= ex_mem_rd;
            mem_wb_wb        <= ex_mem_wb;
        end
    end

endmodule