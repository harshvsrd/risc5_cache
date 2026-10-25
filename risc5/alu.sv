module alu(
    input  logic [31:0] a, b,
    input  logic [3:0]  alu_control,
    output logic [31:0] alu_out,
    output logic        zero
);
    always @(*) begin
        case(alu_control)
            4'b0000: alu_out = a + b;
            4'b0001: alu_out = a - b;
            4'b0010: alu_out = a << b[4:0];
            4'b0011: alu_out = ($signed(a) < $signed(b)) ? 32'd1 : 0;
            4'b0100: alu_out = (a < b) ? 32'd1 : 0;
            4'b0101: alu_out = a ^ b;
            4'b0110: alu_out = a >> b[4:0];
            4'b0111: alu_out = $signed(a) >>> b[4:0];
            4'b1000: alu_out = a | b;
            4'b1001: alu_out = a & b;
            default: alu_out = 32'd0;
        endcase
    end
    assign zero = (alu_out == 0);
endmodule