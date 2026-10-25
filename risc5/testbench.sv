
`timescale 1ns / 1ps

module rv32i_tb;

    logic clk;
    logic reset;

    // DUT status
    integer errors;
    integer stall_count;
    integer flush_count;
    integer cycles;

    logic saw_load_stall;
    logic saw_branch_flush;

    // Instantiate processor
    rv32i_core dut (
        .clk   (clk),
        .reset (reset)
    );

    // 10 ns clock period
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // =========================================================
    // TEST INITIALIZATION
    // =========================================================

    initial begin
        $dumpfile("rv32i_tb.vcd");
        $dumpvars(0, rv32i_tb);

        errors          = 0;
        stall_count     = 0;
        flush_count     = 0;
        cycles          = 0;
        saw_load_stall  = 0;
        saw_branch_flush = 0;

        reset = 1'b1;

        // Initialize data memory.
        for (integer i = 0; i < 64; i = i + 1) begin
            dut.u_mem_stage.dmem.ram[i] = 32'd0;
        end

        // Hold reset across clock edges.
        repeat (3) @(negedge clk);
        reset = 1'b0;

        // Allow the program to execute.
        // The final instruction is an intentional infinite loop.
        repeat (50) @(negedge clk);

        // =====================================================
        // FINAL REGISTER CHECKS
        // =====================================================

        $display("");
        $display("================================================");
        $display("       RV32I PROCESSOR VERIFICATION");
        $display("================================================");

        check_reg(1, 32'd5);
        check_reg(2, 32'd10);
        check_reg(3, 32'd15);
        check_reg(4, 32'd10);
        check_reg(5, 32'd10);
        check_reg(6, 32'd15);
        check_reg(7, 32'd42);

        // x0 must always read as zero.
        if (dut.u_id_stage.rf.rd1 !== 32'd0 &&
            dut.u_id_stage.rf.rs1 == 5'd0) begin
            $display("FAIL: x0 read is not zero");
            errors = errors + 1;
        end
        else begin
            $display("PASS: x0 read is zero");
        end

        // =====================================================
        // MEMORY CHECK
        // =====================================================

        if (dut.u_mem_stage.dmem.ram[0] !== 32'd10) begin
            $display("FAIL: Memory[0] expected 10, got %0d",
                     dut.u_mem_stage.dmem.ram[0]);
            errors = errors + 1;
        end
        else begin
            $display("PASS: Memory[0] = 10");
        end

        // =====================================================
        // HAZARD CHECKS
        // =====================================================

        if (!saw_load_stall) begin
            $display("FAIL: No load-use stall was observed");
            errors = errors + 1;
        end
        else begin
            $display("PASS: Load-use stall observed");
        end

        if (!saw_branch_flush) begin
            $display("FAIL: No branch flush was observed");
            errors = errors + 1;
        end
        else begin
            $display("PASS: Branch flush observed");
        end

        $display("");
        $display("Cycles observed       : %0d", cycles);
        $display("Stall cycles observed : %0d", stall_count);
        $display("Flush cycles observed : %0d", flush_count);
        $display("Total failures        : %0d", errors);
        $display("================================================");

        if (errors == 0) begin
            $display("OVERALL RESULT: PASS");
        end
        else begin
            $display("OVERALL RESULT: FAIL");
            $fatal(1, "Processor verification failed");
        end

        $finish;
    end

    // =========================================================
    // REGISTER CHECK TASK
    // =========================================================

    task automatic check_reg(
        input integer index,
        input logic [31:0] expected
    );
        logic [31:0] actual;
        begin
            actual = dut.u_id_stage.rf.registers[index];

            if (actual !== expected) begin
                $display(
                    "FAIL: x%0d expected %0d (0x%08h), got %0d (0x%08h)",
                    index, expected, expected, actual, actual
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS: x%0d = %0d (0x%08h)",
                    index, actual, actual
                );
            end
        end
    endtask

    // =========================================================
    // PIPELINE MONITOR
    // =========================================================

    always @(posedge clk) begin
        if (!reset) begin
            cycles = cycles + 1;

            if (dut.stall_if) begin
                stall_count = stall_count + 1;
                saw_load_stall = 1'b1;
            end

            if (dut.flush_if) begin
                flush_count = flush_count + 1;
                saw_branch_flush = 1'b1;
            end

            $display(
                "T=%0t | PC=%08h | IF/ID=%08h | EX_ALU=%08h | Stall=%b | Flush=%b",
                $time,
                dut.u_if_stage.pc_reg,
                dut.u_if_stage.if_id_instr,
                dut.u_ex_stage.alu_result,
                dut.stall_if,
                dut.flush_if
            );
        end
    end

    // =========================================================
    // TIMEOUT GUARD
    // =========================================================

    initial begin
        #1000;
        $fatal(1, "TIMEOUT: Simulation did not finish as expected");
    end

endmodule
