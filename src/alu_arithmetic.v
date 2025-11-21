// alu_arithmetic.v
// Arithmetic Logic Unit for mathematical operations
// Supports: ADD, SUB, INC, DEC, MUL, CMP, NEG, ABS, ADDC, SUBB
`timescale 1ns / 1ps

module alu_arithmetic #(
    parameter WIDTH = 32
)(
    input  wire [WIDTH-1:0]     a,
    input  wire [WIDTH-1:0]     b,
    input  wire [3:0]           op,
    output reg  [WIDTH-1:0]     result,
    output reg                  carry_out,
    output reg                  overflow
);
    
    // Extended result for carry detection
    reg [WIDTH:0] extended_result;
    reg signed [WIDTH-1:0] signed_a, signed_b;
    reg signed [2*WIDTH-1:0] mult_result;
    
    // Operation codes
    localparam ADD  = 4'b0000;
    localparam SUB  = 4'b0001;
    localparam INC  = 4'b0010;
    localparam DEC  = 4'b0011;
    localparam MUL  = 4'b0100;
    localparam CMP  = 4'b0101;
    localparam NEG  = 4'b0110;
    localparam ABS  = 4'b0111;
    localparam ADDC = 4'b1000; // Add with carry
    localparam SUBB = 4'b1001; // Subtract with borrow
    
    always @(*) begin
        signed_a = a;
        signed_b = b;
        carry_out = 1'b0;
        overflow = 1'b0;
        extended_result = 0;
        mult_result = 0;
        
        case(op)
            ADD: begin
                extended_result = {1'b0, a} + {1'b0, b};
                result = extended_result[WIDTH-1:0];
                carry_out = extended_result[WIDTH];
                // Overflow: positive + positive = negative or negative + negative = positive
                overflow = (a[WIDTH-1] == b[WIDTH-1]) && (result[WIDTH-1] != a[WIDTH-1]);
            end
            
            SUB: begin
                extended_result = {1'b0, a} - {1'b0, b};
                result = extended_result[WIDTH-1:0];
                carry_out = extended_result[WIDTH];
                // Overflow: positive - negative = negative or negative - positive = positive  
                overflow = (a[WIDTH-1] != b[WIDTH-1]) && (result[WIDTH-1] != a[WIDTH-1]);
            end
            
            INC: begin
                extended_result = {1'b0, a} + 1;
                result = extended_result[WIDTH-1:0];
                carry_out = extended_result[WIDTH];
                overflow = (a == {1'b0, {(WIDTH-1){1'b1}}}); // Overflow when incrementing MAX_POS
            end
            
            DEC: begin
                extended_result = {1'b0, a} - 1;
                result = extended_result[WIDTH-1:0];
                carry_out = extended_result[WIDTH];
                overflow = (a == {1'b1, {(WIDTH-1){1'b0}}}); // Overflow when decrementing MIN_NEG
            end
            
            MUL: begin
                mult_result = signed_a * signed_b;
                result = mult_result[WIDTH-1:0];
                // Overflow if upper bits of multiplication are not all 0s or all 1s
                overflow = (mult_result[2*WIDTH-1:WIDTH] != {WIDTH{mult_result[WIDTH-1]}});
                carry_out = |mult_result[2*WIDTH-1:WIDTH];
            end
            
            CMP: begin
                // Compare: result = a - b, but don't store result, just set flags
                extended_result = {1'b0, a} - {1'b0, b};
                result = 0;
                carry_out = extended_result[WIDTH];
                overflow = (a[WIDTH-1] != b[WIDTH-1]) && (extended_result[WIDTH-1] != a[WIDTH-1]);
            end
            
            NEG: begin
                result = -a;
                overflow = (a == {1'b1, {(WIDTH-1){1'b0}}}); // Overflow when negating MIN_NEG
            end
            
            ABS: begin
                result = (a[WIDTH-1]) ? -a : a;
                overflow = (a == {1'b1, {(WIDTH-1){1'b0}}}); // Overflow when abs(MIN_NEG)
            end
            
            ADDC: begin
                // Add with carry (useful for multi-precision arithmetic)
                extended_result = {1'b0, a} + {1'b0, b} + 1; // +1 represents carry in
                result = extended_result[WIDTH-1:0];
                carry_out = extended_result[WIDTH];
                overflow = (a[WIDTH-1] == b[WIDTH-1]) && (result[WIDTH-1] != a[WIDTH-1]);
            end
            
            SUBB: begin
                // Subtract with borrow
                extended_result = {1'b0, a} - {1'b0, b} - 1; // -1 represents borrow
                result = extended_result[WIDTH-1:0];
                carry_out = extended_result[WIDTH];
                overflow = (a[WIDTH-1] != b[WIDTH-1]) && (result[WIDTH-1] != a[WIDTH-1]);
            end
            
            default: begin
                result = 0;
                carry_out = 0;
                overflow = 0;
            end
        endcase
    end
    
endmodule