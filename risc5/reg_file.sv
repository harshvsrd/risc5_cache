module reg_file (
    input  logic        clk,
    input  logic        we,
    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,
    input  logic [4:0]  rd,
    input  logic [31:0] wd,
    output logic [31:0] rd1,
    output logic [31:0] rd2
);
    logic [31:0] registers [31:0];

    // Asynchronous read: x0 is hardwired with all bits equal to 0
    assign rd1 = (rs1 == 5'd0) ? 32'd0 : registers[rs1];
    assign rd2 = (rs2 == 5'd0) ? 32'd0 : registers[rs2];

    // Synchronous write on negative edge to resolve Read-After-Write hazards
    always_ff @(negedge clk) begin
        if (we && rd != 5'd0)
            registers[rd] <= wd;
    end
endmodule