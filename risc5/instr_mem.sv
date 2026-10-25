module instr_mem (
    input  logic [31:0] addr,
    output logic [31:0] instr
);
    // 64-word ROM for basic testbench verification
    logic [31:0] rom [0:63];
    
    initial begin
        // Pre-loaded Machine Code Program
        rom[0]  = 32'h00500093; // 0x00: addi x1, x0, 5
        rom[1]  = 32'h00a00113; // 0x04: addi x2, x0, 10
        rom[2]  = 32'h002081b3; // 0x08: add  x3, x1, x2  (Tests EX/MEM Forwarding)
        rom[3]  = 32'h40118233; // 0x0C: sub  x4, x3, x1  (Tests MEM/WB Forwarding)
        rom[4]  = 32'h00402023; // 0x10: sw   x4, 0(x0)
        rom[5]  = 32'h00002283; // 0x14: lw   x5, 0(x0)
        rom[6]  = 32'h00128333; // 0x18: add  x6, x5, x1  (Tests Load-Use Stall!)
        rom[7]  = 32'h00330463; // 0x1C: beq  x6, x3, 8   (Tests Branch Flush!)
        rom[8]  = 32'h06300393; // 0x20: addi x7, x0, 99  (BAD PATH: Should be flushed)
        rom[9]  = 32'h02a00393; // 0x24: addi x7, x0, 42  (GOOD PATH: x7 = 42)
        rom[10] = 32'h00000063; // 0x28: beq  x0, x0, 0   (Infinite loop to end)
    end

    // Word-aligned read: discard lowest 2 bits
    assign instr = rom[addr[31:2]]; 
endmodule