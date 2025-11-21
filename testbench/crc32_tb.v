// crc32_tb.v
// Testbench for CRC32 calculator module
`timescale 1ns/1ps

module crc32_tb();
    
    parameter CLK_PERIOD = 10;
    
    // DUT signals
    reg clk, rst_n;
    reg [31:0] data_in;
    reg start;
    reg data_valid;
    wire [31:0] crc_out;
    wire done;
    wire ready;
    
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
    crc32_calculator dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .start(start),
        .data_valid(data_valid),
        .crc_out(crc_out),
        .done(done),
        .ready(ready)
    );
    
    // Task to calculate CRC32 and verify
    task calculate_crc;
        input [31:0] test_data;
        input [31:0] expected_crc;
        begin
            test_count = test_count + 1;
            
            // Wait for ready
            wait(ready == 1);
            @(posedge clk);
            
            // Start CRC calculation
            data_in = test_data;
            data_valid = 1;
            start = 1;
            @(posedge clk);
            start = 0;
            data_valid = 0;
            
            // Wait for completion
            wait(done == 1);
            @(posedge clk);
            
            // Check result
            if (crc_out == expected_crc) begin
                $display("[PASS] Test %0d: Data=%h, CRC=%h", test_count, test_data, crc_out);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: Data=%h", test_count, test_data);
                $display("       Expected CRC: %h", expected_crc);
                $display("       Got CRC:      %h", crc_out);
                fail_count = fail_count + 1;
            end
        end
    endtask
    
    // Main test sequence
    initial begin
        $display("\n===================================");
        $display("CRC32 Calculator Testbench Started");
        $display("===================================\n");
        
        // Initialize
        rst_n = 0;
        start = 0;
        data_valid = 0;
        data_in = 0;
        
        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);
        
        // Test vectors with correct CRC32 values
        $display("Testing CRC32 Calculation:");
        
        // Note: These are standard CRC32 test vectors
        // The actual values depend on byte ordering and implementation
        calculate_crc(32'h00000000, 32'h2144DF1C);
        calculate_crc(32'hFFFFFFFF, 32'hFFFFFFFF);
        calculate_crc(32'h12345678, 32'hAF6D87D2);
        calculate_crc(32'hDEADBEEF, 32'h1A5A601F);
        calculate_crc(32'hAAAAAAAA, 32'hB596E05E);
        calculate_crc(32'h55555555, 32'h6B2DC0BD);
        // Display summary
        #(CLK_PERIOD * 10);
        $display("\n===================================");
        $display("CRC32 Test Summary:");
        $display("Total Tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        if (fail_count == 0) begin
            $display("ALL CRC32 TESTS PASSED!");
        end else begin
            $display("SOME CRC32 TESTS FAILED!");
        end
        $display("===================================\n");
        
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #100000;
        $display("ERROR: CRC32 testbench timeout!");
        $finish;
    end
    
endmodule