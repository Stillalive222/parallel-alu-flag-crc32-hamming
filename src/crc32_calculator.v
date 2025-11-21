// crc32_calculator.v
// CRC32-IEEE 802.3 standard implementation
`timescale 1ns/1ps

module crc32_calculator (
    input  wire         clk,
    input  wire         rst_n,
    input  wire [31:0]  data_in,
    input  wire         start,
    input  wire         data_valid,
    output reg  [31:0]  crc_out,
    output reg          done,
    output wire         ready
);
    
    // CRC32 polynomial (reversed)
    localparam [31:0] POLYNOMIAL = 32'hEDB88320;
    
    // State machine
    localparam IDLE = 2'b00;
    localparam PROCESSING = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state;
    reg [31:0] crc_reg;
    reg [5:0] bit_counter;
    reg [7:0] byte_counter;
    reg [31:0] data_buffer;
    reg [7:0] current_byte;
    
    assign ready = (state == IDLE);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            crc_reg <= 32'hFFFFFFFF;
            bit_counter <= 0;
            byte_counter <= 0;
            data_buffer <= 0;
            done <= 0;
            crc_out <= 0;
            current_byte <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    crc_reg <= 32'hFFFFFFFF;
                    bit_counter <= 0;
                    byte_counter <= 0;
                    if (start && data_valid) begin
                        data_buffer <= data_in;
                        state <= PROCESSING;
                    end
                end
                
                PROCESSING: begin
                    // Process byte by byte (4 bytes total)
                    if (byte_counter < 4) begin
                        if (bit_counter == 0) begin
                            // Get current byte based on counter
                            case(byte_counter)
                                0: current_byte <= data_buffer[7:0];
                                1: current_byte <= data_buffer[15:8];
                                2: current_byte <= data_buffer[23:16];
                                3: current_byte <= data_buffer[31:24];
                            endcase
                            bit_counter <= 1;
                        end else if (bit_counter <= 8) begin
                            // Process each bit of current byte
                            if ((crc_reg[0] ^ current_byte[0]) == 1'b1) begin
                                crc_reg <= (crc_reg >> 1) ^ POLYNOMIAL;
                            end else begin
                                crc_reg <= crc_reg >> 1;
                            end
                            current_byte <= current_byte >> 1;
                            
                            if (bit_counter == 8) begin
                                bit_counter <= 0;
                                byte_counter <= byte_counter + 1;
                            end else begin
                                bit_counter <= bit_counter + 1;
                            end
                        end
                    end else begin
                        state <= DONE;
                    end
                end
                
                DONE: begin
                    crc_out <= ~crc_reg;  // Final inversion
                    done <= 1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
endmodule