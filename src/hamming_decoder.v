// hamming_decoder.v
// Hamming(32,26) error detection and correction module
// Detects and corrects single-bit errors, detects double-bit errors
`timescale 1ns / 1ps
module hamming_decoder (
    input  wire         clk,
    input  wire         rst_n,
    input  wire [31:0]  encoded_data,
    input  wire         start,
    output reg  [25:0]  decoded_data,
    output reg  [5:0]   syndrome,
    output reg          single_error_detected,
    output reg          double_error_detected,
    output reg          error_corrected,
    output reg          done
);
    
    // Parity check matrix positions for Hamming(32,26)
    // P1 = positions 1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31
    // P2 = positions 2,3,6,7,10,11,14,15,18,19,22,23,26,27,30,31
    // P4 = positions 4,5,6,7,12,13,14,15,20,21,22,23,28,29,30,31
    // P8 = positions 8,9,10,11,12,13,14,15,24,25,26,27,28,29,30,31
    // P16 = positions 16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31
    // P32 = overall parity
    
    reg [31:0] data_reg;
    reg [31:0] corrected_data;
    reg parity_p1, parity_p2, parity_p4, parity_p8, parity_p16, parity_p32;
    
    // ALU interface for XOR operations
    reg [31:0] alu_operand_a, alu_operand_b;
    reg [5:0] alu_opcode;
    reg alu_enable;
    wire [31:0] alu_result;
    wire [3:0] alu_flags;
    wire alu_valid;
    
    // State machine
    localparam IDLE = 3'b000;
    localparam CALC_PARITY = 3'b001;
    localparam CHECK_ERROR = 3'b010;
    localparam CORRECT_ERROR = 3'b011;
    localparam EXTRACT_DATA = 3'b100;
    localparam DONE = 3'b101;
    
    reg [2:0] state, next_state;
    
    // Instantiate ALU for parity calculations
    parallel_alu_bank #(
        .DATA_WIDTH(32)
    ) hamming_alu (
        .clk(clk),
        .rst_n(rst_n),
        .operand_a(alu_operand_a),
        .operand_b(alu_operand_b),
        .opcode(alu_opcode),
        .enable(alu_enable),
        .alu_select(1'b1), // Use logic ALU
        .result(alu_result),
        .flags(alu_flags),
        .valid(alu_valid),
        .busy()
    );
    
    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start)
                    next_state = CALC_PARITY;
            end
            CALC_PARITY: begin
                next_state = CHECK_ERROR;
            end
            CHECK_ERROR: begin
                if (syndrome != 0)
                    next_state = CORRECT_ERROR;
                else
                    next_state = EXTRACT_DATA;
            end
            CORRECT_ERROR: begin
                next_state = EXTRACT_DATA;
            end
            EXTRACT_DATA: begin
                next_state = DONE;
            end
            DONE: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    // Parity calculation function
    function automatic parity_calc;
        input [31:0] data;
        input [31:0] mask;
        reg result;
        reg [31:0] temp;
        integer i;
        begin
            temp = data & mask;
            result = 0;
            for (i = 0; i < 32; i = i + 1) begin
                result = result ^ temp[i];
            end
            parity_calc = result;
        end
    endfunction
    
    // Main processing logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 0;
            corrected_data <= 0;
            syndrome <= 0;
            single_error_detected <= 0;
            double_error_detected <= 0;
            error_corrected <= 0;
            done <= 0;
            decoded_data <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    single_error_detected <= 0;
                    double_error_detected <= 0;
                    error_corrected <= 0;
                    if (start) begin
                        data_reg <= encoded_data;
                        corrected_data <= encoded_data;
                    end
                end
                
                CALC_PARITY: begin
                    // Calculate parity bits
                    parity_p1 = parity_calc(data_reg, 32'hAAAAAAAA);
                    parity_p2 = parity_calc(data_reg, 32'hCCCCCCCC);
                    parity_p4 = parity_calc(data_reg, 32'hF0F0F0F0);
                    parity_p8 = parity_calc(data_reg, 32'hFF00FF00);
                    parity_p16 = parity_calc(data_reg, 32'hFFFF0000);
                    parity_p32 = ^data_reg; // Overall parity
                    
                    // Form syndrome
                    syndrome <= {parity_p32, parity_p16, parity_p8, parity_p4, parity_p2, parity_p1};
                end
                
                CHECK_ERROR: begin
                    if (syndrome[5:0] != 0) begin
                        if (parity_p32) begin
                            // Single-bit error
                            single_error_detected <= 1;
                        end else begin
                            // Double-bit error
                            double_error_detected <= 1;
                        end
                    end
                end
                
                CORRECT_ERROR: begin
                    if (single_error_detected && syndrome[4:0] != 0) begin
                        // Correct the error at position indicated by syndrome
                        corrected_data[syndrome[4:0] - 1] <= ~corrected_data[syndrome[4:0] - 1];
                        error_corrected <= 1;
                    end
                end
                
                EXTRACT_DATA: begin
                    // Extract the 26 data bits (skipping parity positions)
                    // Positions: 3,5,6,7,9,10,11,12,13,14,15,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31
                    decoded_data[0] <= corrected_data[2];   // Position 3
                    decoded_data[1] <= corrected_data[4];   // Position 5
                    decoded_data[2] <= corrected_data[5];   // Position 6
                    decoded_data[3] <= corrected_data[6];   // Position 7
                    decoded_data[4] <= corrected_data[8];   // Position 9
                    decoded_data[5] <= corrected_data[9];   // Position 10
                    decoded_data[6] <= corrected_data[10];  // Position 11
                    decoded_data[7] <= corrected_data[11];  // Position 12
                    decoded_data[8] <= corrected_data[12];  // Position 13
                    decoded_data[9] <= corrected_data[13];  // Position 14
                    decoded_data[10] <= corrected_data[14]; // Position 15
                    decoded_data[11] <= corrected_data[16]; // Position 17
                    decoded_data[12] <= corrected_data[17]; // Position 18
                    decoded_data[13] <= corrected_data[18]; // Position 19
                    decoded_data[14] <= corrected_data[19]; // Position 20
                    decoded_data[15] <= corrected_data[20]; // Position 21
                    decoded_data[16] <= corrected_data[21]; // Position 22
                    decoded_data[17] <= corrected_data[22]; // Position 23
                    decoded_data[18] <= corrected_data[23]; // Position 24
                    decoded_data[19] <= corrected_data[24]; // Position 25
                    decoded_data[20] <= corrected_data[25]; // Position 26
                    decoded_data[21] <= corrected_data[26]; // Position 27
                    decoded_data[22] <= corrected_data[27]; // Position 28
                    decoded_data[23] <= corrected_data[28]; // Position 29
                    decoded_data[24] <= corrected_data[29]; // Position 30
                    decoded_data[25] <= corrected_data[30]; // Position 31
                end
                
                DONE: begin
                    done <= 1;
                end
            endcase
        end
    end
    
endmodule