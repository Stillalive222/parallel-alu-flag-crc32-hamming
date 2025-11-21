// alu_logic.v
// Logic Unit for bitwise and shift operations
// Supports: AND, OR, XOR, NOT, NAND, NOR, SHL, SHR, ROL, ROR
`timescale 1ns / 1ps

module alu_logic #(
    parameter WIDTH = 32
)(
    input  wire [WIDTH-1:0]     a,
    input  wire [WIDTH-1:0]     b,
    input  wire [3:0]           op,
    output reg  [WIDTH-1:0]     result,
    output reg                  carry_out,
    output reg                  overflow
);
    
    // Shift amount (using lower 5 bits of b for 32-bit shifts)
    wire [4:0] shift_amount;
    assign shift_amount = b[4:0];
    
    // Operation codes
    localparam AND  = 4'b0000;
    localparam OR   = 4'b0001;
    localparam XOR  = 4'b0010;
    localparam NOT  = 4'b0011;
    localparam NAND = 4'b0100;
    localparam NOR  = 4'b0101;
    localparam SHL  = 4'b0110; // Shift left logical
    localparam SHR  = 4'b0111; // Shift right logical
    localparam SAR  = 4'b1000; // Shift arithmetic right
    localparam ROL  = 4'b1001; // Rotate left
    localparam ROR  = 4'b1010; // Rotate right
    localparam XNOR = 4'b1011;
    localparam BSET = 4'b1100; // Bit set
    localparam BCLR = 4'b1101; // Bit clear
    localparam BTGL = 4'b1110; // Bit toggle
    
    always @(*) begin
        carry_out = 1'b0;
        overflow = 1'b0;
        
        case(op)
            AND: begin
                result = a & b;
            end
            
            OR: begin
                result = a | b;
            end
            
            XOR: begin
                result = a ^ b;
            end
            
            NOT: begin
                result = ~a;
            end
            
            NAND: begin
                result = ~(a & b);
            end
            
            NOR: begin
                result = ~(a | b);
            end
            
            SHL: begin
                if (shift_amount != 0) begin
                    result = a << shift_amount;
                    carry_out = a[WIDTH - shift_amount]; // Last bit shifted out
                end else begin
                    result = a;
                    carry_out = 0;
                end
            end
            
            SHR: begin
                if (shift_amount != 0) begin
                    result = a >> shift_amount;
                    carry_out = a[shift_amount - 1]; // Last bit shifted out
                end else begin
                    result = a;
                    carry_out = 0;
                end
            end
            
            SAR: begin
                // Arithmetic shift right (sign extension)
                result = $signed(a) >>> shift_amount;
                if (shift_amount != 0)
                    carry_out = a[shift_amount - 1];
                else
                    carry_out = 0;
            end
            
            ROL: begin
                // Rotate left
                if (shift_amount != 0) begin
                    result = (a << shift_amount) | (a >> (WIDTH - shift_amount));
                    carry_out = a[WIDTH - shift_amount];
                end else begin
                    result = a;
                    carry_out = 0;
                end
            end
            
            ROR: begin
                // Rotate right
                if (shift_amount != 0) begin
                    result = (a >> shift_amount) | (a << (WIDTH - shift_amount));
                    carry_out = a[shift_amount - 1];
                end else begin
                    result = a;
                    carry_out = 0;
                end
            end
            
            XNOR: begin
                result = ~(a ^ b);
            end
            
            BSET: begin
                // Set bit at position b[4:0]
                result = a | (1 << shift_amount);
            end
            
            BCLR: begin
                // Clear bit at position b[4:0]
                result = a & ~(1 << shift_amount);
            end
            
            BTGL: begin
                // Toggle bit at position b[4:0]
                result = a ^ (1 << shift_amount);
            end
            
            default: begin
                result = 0;
                carry_out = 0;
                overflow = 0;
            end
        endcase
    end
    
endmodule