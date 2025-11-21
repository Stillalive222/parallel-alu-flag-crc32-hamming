// system_integration_tb.v
// System-level integration testbench
// Tests complete data flow through ALU, CRC32, and Hamming modules

`timescale 1ns/1ps

module system_integration_tb();
    
    parameter CLK_PERIOD = 10;
    parameter DATA_WIDTH = 32;
    
    // System signals
    reg clk, rst_n;
    reg [31:0] test_data;
    reg system_start;
    
    // ALU signals
    reg [DATA_WIDTH-1:0] alu_operand_a, alu_operand_b;
    reg [5:0] alu_opcode;
    reg alu_enable;
    reg alu_select;
    wire [DATA_WIDTH-1:0] alu_result;
    wire [3:0] alu_flags;
    wire alu_valid;
    wire alu_busy;
    
    // CRC32 signals
    reg crc_start;
    reg crc_data_valid;
    wire [31:0] crc_out;
    wire crc_done;
    wire crc_ready;
    
    // Hamming signals
    reg hamming_start;
    wire [25:0] decoded_data;
    wire [5:0] syndrome;
    wire single_error;
    wire double_error;
    wire error_corrected;
    wire hamming_done;
    
    // Test statistics
    integer test_count = 0;
    integer cycle_count = 0;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Cycle counter
    always @(posedge clk) begin
        if (!rst_n)
            cycle_count <= 0;
        else
            cycle_count <= cycle_count + 1;
    end
    
    // Module instantiations
    parallel_alu_bank #(
        .DATA_WIDTH(DATA_WIDTH)
    ) alu_inst (
        .clk(clk),
        .rst_n(rst_n),
        .operand_a(alu_operand_a),
        .operand_b(alu_operand_b),
        .opcode(alu_opcode),
        .enable(alu_enable),
        .alu_select(alu_select),
        .result(alu_result),
        .flags(alu_flags),
        .valid(alu_valid),
        .busy(alu_busy)
    );
    
    crc32_calculator crc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(alu_result),
        .start(crc_start),
        .data_valid(crc_data_valid),
        .crc_out(crc_out),
        .done(crc_done),
        .ready(crc_ready)
    );
    
    hamming_decoder hamming_inst (
        .clk(clk),
        .rst_n(rst_n),
        .encoded_data(crc_out),
        .start(hamming_start),
        .decoded_data(decoded_data),
        .syndrome(syndrome),
        .single_error_detected(single_error),
        .double_error_detected(double_error),
        .error_corrected(error_corrected),
        .done(hamming_done)
    );
    
    // Task: Complete system flow test
    task test_system_flow;
        input [31:0] data_a;
        input [31:0] data_b;
        input [5:0] operation;
        begin
            test_count = test_count + 1;
            $display("\n[Test %0d] System Flow Test", test_count);
            $display("Input A: %h, Input B: %h, Operation: %b", data_a, data_b, operation);
            
            // Step 1: ALU Operation
            @(posedge clk);
            alu_operand_a = data_a;
            alu_operand_b = data_b;
            alu_opcode = operation;
            alu_select = (operation[5:4] == 2'b01) ? 1 : 0;
            alu_enable = 1;
            @(posedge clk);
            alu_enable = 0;
            
            wait(alu_valid == 1);
            $display("ALU Result: %h, Flags: %b (Cycle %0d)", alu_result, alu_flags, cycle_count);
            
            // Step 2: CRC32 Calculation
            @(posedge clk);
            crc_data_valid = 1;
            crc_start = 1;
            @(posedge clk);
            crc_start = 0;
            crc_data_valid = 0;
            
            wait(crc_done == 1);
            $display("CRC32 Output: %h (Cycle %0d)", crc_out, cycle_count);
            
            // Step 3: Hamming Decode
            @(posedge clk);
            hamming_start = 1;
            @(posedge clk);
            hamming_start = 0;
            
            wait(hamming_done == 1);
            $display("Hamming Decoded: %h, Syndrome: %h (Cycle %0d)", decoded_data, syndrome, cycle_count);
            
            if (single_error)
                $display("Single-bit error detected and corrected");
            if (double_error)
                $display("Double-bit error detected");
                
            @(posedge clk);
        end
    endtask
    
    // Main test sequence
    initial begin
        $display("\n=====================================");
        $display("System Integration Testbench Started");
        $display("=====================================");
        
        // Open waveform dump file
        $dumpfile("system_integration_tb.vcd");
        $dumpvars(0, system_integration_tb);
        
        // Initialize
        rst_n = 0;
        alu_enable = 0;
        crc_start = 0;
        crc_data_valid = 0;
        hamming_start = 0;
        alu_operand_a = 0;
        alu_operand_b = 0;
        alu_opcode = 0;
        alu_select = 0;
        
        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);
        
        // Test different data flows
        $display("\n=== Running System Integration Tests ===");
        
        // Test 1: Arithmetic -> CRC32 -> Hamming
        test_system_flow(32'h12345678, 32'h87654321, 6'b000000); // ADD
        
        // Test 2: Logic -> CRC32 -> Hamming
        test_system_flow(32'hAAAAAAAA, 32'h55555555, 6'b010010); // XOR
        
        // Test 3: Complex arithmetic
        test_system_flow(32'hDEADBEEF, 32'h00000010, 6'b000100); // MUL
        
        // Test 4: Shift operation
        test_system_flow(32'h00000001, 32'h00000008, 6'b010110); // SHL
        
        // Test 5: Stress test with random data
        $display("\n=== Random Data Stress Test ===");
        repeat(5) begin
            test_system_flow($random, $random, $random % 32);
        end
        
        // Performance metrics
        #(CLK_PERIOD * 10);
        $display("\n=====================================");
        $display("System Integration Test Summary:");
        $display("Total Tests: %0d", test_count);
        $display("Total Clock Cycles: %0d", cycle_count);
        $display("Average Cycles per Test: %0d", cycle_count / test_count);
        $display("=====================================\n");
        
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #500000;
        $display("ERROR: System testbench timeout!");
        $finish;
    end
    
endmodule