// flag_generator.v
// Flag generation module for ALU operations
// Generates Zero, Sign, Carry, and Overflow flags

module flag_generator #(
    parameter WIDTH = 32
)(
    input  wire [WIDTH-1:0]     result,
    input  wire                 carry_alu0,
    input  wire                 overflow_alu0,
    input  wire                 carry_alu1,
    input  wire                 overflow_alu1,
    input  wire                 alu_select,
    output wire                 zero_flag,
    output wire                 sign_flag,
    output wire                 carry_flag,
    output wire                 overflow_flag
);
    
    // Zero flag: Set when result is zero
    assign zero_flag = (result == {WIDTH{1'b0}});
    
    // Sign flag: MSB of result (for signed operations)
    assign sign_flag = result[WIDTH-1];
    
    // Carry flag: Depends on which ALU is selected
    assign carry_flag = (alu_select == 0) ? carry_alu0 : carry_alu1;
    
    // Overflow flag: Depends on which ALU is selected
    assign overflow_flag = (alu_select == 0) ? overflow_alu0 : overflow_alu1;
    
endmodule