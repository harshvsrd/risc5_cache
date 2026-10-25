module data_mem (
    input  logic        clk,
    input  logic        we,
    input  logic [3:0]  byte_en,
    input  logic [31:0] addr,
    input  logic [31:0] write_data,
    output logic [31:0] read_data
);
    logic [31:0] ram [0:63];

    assign read_data = ram[addr[31:2]];

    always_ff @(posedge clk) begin
        if (we) begin
            if (byte_en[0]) ram[addr[31:2]][7:0]   <= write_data[7:0];
            if (byte_en[1]) ram[addr[31:2]][15:8]  <= write_data[15:8];
            if (byte_en[2]) ram[addr[31:2]][23:16] <= write_data[23:16];
            if (byte_en[3]) ram[addr[31:2]][31:24] <= write_data[31:24];
        end
    end
endmodule