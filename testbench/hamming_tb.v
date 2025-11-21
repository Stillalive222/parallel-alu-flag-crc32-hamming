// hamming_tb.v
// Testbench for Hamming decoder module
// Tests error detection and correction capabilities

`timescale 1ns/1ps

module hamming_tb();
    
    parameter CLK_PERIOD = 10;
    
    // DUT signals
    reg clk, rst_n;
    reg [31:0] encoded_data;
    reg start;
    wire [25:0] decoded_data;
    wire [5:0] syndrome;
    wire single_error_detected;
    wire double_error_detected;
    wire error_corrected;
    wire done;
    
    // Test variables
    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    integer i;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // DUT instantiation
    hamming_decoder dut (
        .clk(clk),
        .rst_n(rst_n),
        .encoded_data(encoded_data),
        .start(start),
        .decoded_data(decoded_data),
        .syndrome(syndrome),
        .single_error_detected(single_error_detected),
        .double_error_detected(double_error_detected),
        .error_corrected(error_corrected),
        .done(done)
    );
    
    // Function to inject single-bit error
    function [31:0] inject_single_error;
        input [31:0] data;
        input [4:0] bit_pos;
        begin
            inject_single_error = data ^ (1 << bit_pos);
        end
    endfunction
    
    // Function to inject double-bit error
    function [31:0] inject_double_error;
        input [31:0] data;
        input [4:0] bit_pos1;
        input [4:0] bit_pos2;
        begin
            inject_double_error = data ^ (1 << bit_pos1) ^ (1 << bit_pos2);
        end
    endfunction
    
    // Task to test Hamming decoding
    task test_hamming_decode;
        input [31:0] test_data;
        input [25:0] expected_decoded;
        input expected_single_error;
        input expected_double_error;
        begin
            test_count = test_count + 1;
            
            @(posedge clk);
            encoded_data = test_data;
            start = 1;
            @(posedge clk);
            start = 0;
            
            // Wait for completion
            wait(done == 1);
            @(posedge clk);
            
            // Check results
            if (decoded_data == expected_decoded && 
                single_error_detected == expected_single_error &&
                double_error_detected == expected_double_error) begin
                $display("[PASS] Test %0d: Encoded=%h, Decoded=%h, Syndrome=%h", 
                        test_count, test_data, decoded_data, syndrome);
                if (single_error_detected)
                    $display("       Single error detected and corrected");
                if (double_error_detected)
                    $display("       Double error detected");
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: Encoded=%h", test_count, test_data);
                $display("       Expected: Decoded=%h, Single=%b, Double=%b", 
                        expected_decoded, expected_single_error, expected_double_error);
                $display("       Got:      Decoded=%h, Single=%b, Double=%b, Syndrome=%h", 
                        decoded_data, single_error_detected, double_error_detected, syndrome);
                fail_count = fail_count + 1;
            end
            
            @(posedge clk);
        end
    endtask
    
    // Main test sequence
    initial begin
        $display("\n===================================");
        $display("Hamming Decoder Testbench Started");
        $display("===================================\n");
        
        // Open waveform dump file
        $dumpfile("hamming_tb.vcd");
        $dumpvars(0, hamming_tb);
        
        // Initialize
        rst_n = 0;
        start = 0;
        encoded_data = 0;
        
        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);
        
        // Test 1: No error case
        $display("Test: No Error Cases");
        test_hamming_decode(32'hA5A5A5A5, 26'h1234567, 0, 0);
        test_hamming_decode(32'h5A5A5A5A, 26'h0ABCDEF, 0, 0);
        
        // Test 2: Single-bit error cases
        $display("\nTest: Single-Bit Error Cases");
        for (i = 0; i < 5; i = i + 1) begin
            test_hamming_decode(inject_single_error(32'h12345678, i*7), 26'h0987654, 1, 0);
        end
        
        // Test 3: Double-bit error cases
        $display("\nTest: Double-Bit Error Cases");
        for (i = 0; i < 3; i = i + 1) begin
            test_hamming_decode(inject_double_error(32'hDEADBEEF, i*5, i*5+3), 26'h1FEDCBA, 0, 1);
        end
        
        // Test 4: Boundary conditions
        $display("\nTest: Boundary Conditions");
        test_hamming_decode(32'h00000000, 26'h0000000, 0, 0);
        test_hamming_decode(32'hFFFFFFFF, 26'h3FFFFFF, 0, 0);
        
        // Test 5: Error at parity bit positions
        $display("\nTest: Error at Parity Positions");
        test_hamming_decode(inject_single_error(32'h87654321, 0), 26'h1111111, 1, 0);  // P1
        test_hamming_decode(inject_single_error(32'h87654321, 1), 26'h1111111, 1, 0);  // P2
        test_hamming_decode(inject_single_error(32'h87654321, 3), 26'h1111111, 1, 0);  // P4
        test_hamming_decode(inject_single_error(32'h87654321, 7), 26'h1111111, 1, 0);  // P8
        
        // Display summary
        #(CLK_PERIOD * 10);
        $display("\n===================================");
        $display("Hamming Test Summary:");
        $display("Total Tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        if (fail_count == 0) begin
            $display("ALL HAMMING TESTS PASSED!");
        end else begin
            $display("SOME HAMMING TESTS FAILED!");
        end
        $display("===================================\n");
        
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #100000;
        $display("ERROR: Hamming testbench timeout!");
        $finish;
    end
    
endmodule