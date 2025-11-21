// parallel_alu_tb.v
// Comprehensive testbench for parallel ALU bank
// Tests all arithmetic, logic operations and flag generation

`timescale 1ns/1ps

module parallel_alu_tb();
    
    // Parameters
    parameter DATA_WIDTH = 32;
    parameter CLK_PERIOD = 10;
    
    // DUT signals
    reg clk, rst_n;
    reg [DATA_WIDTH-1:0] operand_a, operand_b;
    reg [5:0] opcode;
    reg enable;
    reg alu_select;
    wire [DATA_WIDTH-1:0] result;
    wire [3:0] flags;
    wire valid;
    wire busy;
    
    // Test variables
    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // DUT instantiation
    parallel_alu_bank #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .opcode(opcode),
        .enable(enable),
        .alu_select(alu_select),
        .result(result),
        .flags(flags),
        .valid(valid),
        .busy(busy)
    );
    
    // Task to perform ALU operation and check result
    task perform_operation;
        input [DATA_WIDTH-1:0] a;
        input [DATA_WIDTH-1:0] b;
        input [5:0] op;
        input alu_sel;
        input [DATA_WIDTH-1:0] expected_result;
        input [3:0] expected_flags;
        begin
            test_count = test_count + 1;
            
            @(posedge clk);
            operand_a = a;
            operand_b = b;
            opcode = op;
            alu_select = alu_sel;
            enable = 1;
            
            @(posedge clk);
            enable = 0;
            
            // Wait for valid signal
            wait(valid == 1);
            @(posedge clk);
            
            // Check results
            if (result == expected_result && flags == expected_flags) begin
                $display("[PASS] Test %0d: Op=%b, A=%h, B=%h, Result=%h, Flags=%b", 
                        test_count, op, a, b, result, flags);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: Op=%b, A=%h, B=%h", test_count, op, a, b);
                $display("       Expected: Result=%h, Flags=%b", expected_result, expected_flags);
                $display("       Got:      Result=%h, Flags=%b", result, flags);
                fail_count = fail_count + 1;
            end
            
            @(posedge clk);
        end
    endtask
    
    // Task to test arithmetic operations
    task test_arithmetic_operations;
        begin
            $display("\n=== Testing Arithmetic Operations ===");
            
            // Test ADD
            perform_operation(32'h00000005, 32'h00000003, 6'b000000, 0, 32'h00000008, 4'b0001); // 5 + 3 = 8
            perform_operation(32'hFFFFFFFF, 32'h00000001, 6'b000000, 0, 32'h00000000, 4'b1001); // -1 + 1 = 0, carry & zero
            perform_operation(32'h7FFFFFFF, 32'h00000001, 6'b000000, 0, 32'h80000000, 4'b0110); // Overflow test
            
            // Test SUB
            perform_operation(32'h00000008, 32'h00000003, 6'b000001, 0, 32'h00000005, 4'b0000); // 8 - 3 = 5
            perform_operation(32'h00000000, 32'h00000001, 6'b000001, 0, 32'hFFFFFFFF, 4'b1010); // 0 - 1 = -1
            perform_operation(32'h80000000, 32'h00000001, 6'b000001, 0, 32'h7FFFFFFF, 4'b0100); // Overflow
            
            // Test INC
            perform_operation(32'h00000005, 32'h00000000, 6'b000010, 0, 32'h00000006, 4'b0000); // 5++ = 6
            perform_operation(32'hFFFFFFFF, 32'h00000000, 6'b000010, 0, 32'h00000000, 4'b1001); // -1++ = 0
            
            // Test DEC
            perform_operation(32'h00000005, 32'h00000000, 6'b000011, 0, 32'h00000004, 4'b0000); // 5-- = 4
            perform_operation(32'h00000000, 32'h00000000, 6'b000011, 0, 32'hFFFFFFFF, 4'b1010); // 0-- = -1
            
            // Test MUL
            perform_operation(32'h00000004, 32'h00000003, 6'b000100, 0, 32'h0000000C, 4'b0000); // 4 * 3 = 12
            perform_operation(32'hFFFFFFFF, 32'h00000002, 6'b000100, 0, 32'hFFFFFFFE, 4'b0010); // -1 * 2 = -2
            
            // Test NEG
            perform_operation(32'h00000005, 32'h00000000, 6'b000110, 0, 32'hFFFFFFFB, 4'b0010); // -5
            perform_operation(32'hFFFFFFFF, 32'h00000000, 6'b000110, 0, 32'h00000001, 4'b0000); // -(-1) = 1
            
            // Test ABS
            perform_operation(32'hFFFFFFFB, 32'h00000000, 6'b000111, 0, 32'h00000005, 4'b0000); // abs(-5) = 5
            perform_operation(32'h00000005, 32'h00000000, 6'b000111, 0, 32'h00000005, 4'b0000); // abs(5) = 5
        end
    endtask
    
    // Task to test logic operations
    task test_logic_operations;
        begin
            $display("\n=== Testing Logic Operations ===");
            
            // Test AND
            perform_operation(32'hFF00FF00, 32'h0F0F0F0F, 6'b010000, 1, 32'h0F000F00, 4'b0000);
            
            // Test OR
            perform_operation(32'hFF00FF00, 32'h0F0F0F0F, 6'b010001, 1, 32'hFF0FFF0F, 4'b0010);
            
            // Test XOR
            perform_operation(32'hFF00FF00, 32'h0F0F0F0F, 6'b010010, 1, 32'hF00FF00F, 4'b0010);
            
            // Test NOT
            perform_operation(32'hAAAAAAAA, 32'h00000000, 6'b010011, 1, 32'h55555555, 4'b0000);
            
            // Test NAND
            perform_operation(32'hFF00FF00, 32'h0F0F0F0F, 6'b010100, 1, 32'hF0FFF0FF, 4'b0010);
            
            // Test NOR
            perform_operation(32'hFF00FF00, 32'h0F0F0F0F, 6'b010101, 1, 32'h00F000F0, 4'b0000);
            
            // Test SHL (Shift Left)
            perform_operation(32'h00000001, 32'h00000004, 6'b010110, 1, 32'h00000010, 4'b0000); // 1 << 4 = 16
            perform_operation(32'h80000000, 32'h00000001, 6'b010110, 1, 32'h00000000, 4'b1001); // Shift out MSB
            
            // Test SHR (Shift Right)
            perform_operation(32'h00000010, 32'h00000002, 6'b010111, 1, 32'h00000004, 4'b0000); // 16 >> 2 = 4
            perform_operation(32'h00000001, 32'h00000001, 6'b010111, 1, 32'h00000000, 4'b1001); // Shift out LSB
            
            // Test ROL (Rotate Left)
            perform_operation(32'h80000001, 32'h00000001, 6'b011001, 1, 32'h00000003, 4'b1000); // Rotate left by 1
            
            // Test ROR (Rotate Right)
            perform_operation(32'h00000003, 32'h00000001, 6'b011010, 1, 32'h80000001, 4'b1000); // Rotate right by 1
        end
    endtask
    
    // Task to test flag generation
    task test_flag_generation;
        begin
            $display("\n=== Testing Flag Generation ===");
            
            // Test Zero Flag
            perform_operation(32'h00000005, 32'h00000005, 6'b000001, 0, 32'h00000000, 4'b1001); // 5-5=0, Zero flag set
            
            // Test Sign Flag (negative result)
            perform_operation(32'h00000000, 32'h00000001, 6'b000001, 0, 32'hFFFFFFFF, 4'b1010); // 0-1=-1, Sign flag set
            
            // Test Carry Flag
            perform_operation(32'hFFFFFFFF, 32'h00000002, 6'b000000, 0, 32'h00000001, 4'b1000); // Carry flag set
            
            // Test Overflow Flag
            perform_operation(32'h7FFFFFFF, 32'h00000001, 6'b000000, 0, 32'h80000000, 4'b0110); // Overflow flag set
        end
    endtask
    
    // Task to test parallel execution
    task test_parallel_execution;
        integer i;
        begin
            $display("\n=== Testing Parallel Execution ===");
            
            // Rapid succession of operations
            for (i = 0; i < 10; i = i + 1) begin
                @(posedge clk);
                operand_a = $random;
                operand_b = $random;
                opcode = $random % 16;
                alu_select = i % 2;
                enable = 1;
                @(posedge clk);
                enable = 0;
                wait(valid == 1);
                $display("Parallel Test %0d: Result=%h, Flags=%b", i, result, flags);
            end
        end
    endtask
    
    // Main test sequence
    initial begin
        // Initialize
        $display("===================================");
        $display("Parallel ALU Bank Testbench Started");
        $display("===================================");
        
        // Open waveform dump file
        $dumpfile("parallel_alu_tb.vcd");
        $dumpvars(0, parallel_alu_tb);
        
        // Reset sequence
        rst_n = 0;
        enable = 0;
        operand_a = 0;
        operand_b = 0;
        opcode = 0;
        alu_select = 0;
        
        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);
        
        // Run tests
        test_arithmetic_operations();
        test_logic_operations();
        test_flag_generation();
        test_parallel_execution();
        
        // Display summary
        #(CLK_PERIOD * 10);
        $display("\n===================================");
        $display("Test Summary:");
        $display("Total Tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        if (fail_count == 0) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("SOME TESTS FAILED!");
        end
        $display("===================================\n");
        
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #1000000;
        $display("ERROR: Testbench timeout!");
        $finish;
    end
    
endmodule