// parallel_alu_bank.v
// Top-level module for parallel ALU bank with dual execution paths
// Author: COA Project
// Description: Implements parallel ALU with independent arithmetic and logic units

module parallel_alu_bank #(
    parameter DATA_WIDTH = 32
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire [DATA_WIDTH-1:0]    operand_a,
    input  wire [DATA_WIDTH-1:0]    operand_b,
    input  wire [5:0]               opcode,      // 6-bit opcode for more operations
    input  wire                     enable,
    input  wire                     alu_select,  // 0: ALU0, 1: ALU1
    output reg  [DATA_WIDTH-1:0]    result,
    output reg  [3:0]               flags,       // {Carry, Overflow, Sign, Zero}
    output reg                      valid,
    output wire                     busy
);

    // Internal signals
    wire [DATA_WIDTH-1:0] alu0_result, alu1_result;
    wire [DATA_WIDTH-1:0] selected_result;
    wire carry_out_alu0, overflow_alu0;
    wire carry_out_alu1, overflow_alu1;
    wire zero_flag, sign_flag, carry_flag, overflow_flag;
    
    // Operation type signals
    wire is_arithmetic, is_logic;
    reg  operation_valid;
    
    // Pipeline registers for parallel execution
    reg [DATA_WIDTH-1:0] operand_a_reg, operand_b_reg;
    reg [5:0] opcode_reg;
    reg alu_select_reg;
    reg enable_reg;
    
    // State machine for control
    localparam IDLE = 2'b00;
    localparam EXECUTE = 2'b01;
    localparam COMPLETE = 2'b10;
    
    reg [1:0] current_state, next_state;
    
    // Determine operation type from opcode
    assign is_arithmetic = (opcode[5:4] == 2'b00); // Arithmetic ops: 00xxxx
    assign is_logic = (opcode[5:4] == 2'b01);      // Logic ops: 01xxxx
    
    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (enable)
                    next_state = EXECUTE;
            end
            EXECUTE: begin
                next_state = COMPLETE;
            end
            COMPLETE: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    // Input register stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            operand_a_reg <= 0;
            operand_b_reg <= 0;
            opcode_reg <= 0;
            alu_select_reg <= 0;
            enable_reg <= 0;
        end else if (enable && current_state == IDLE) begin
            operand_a_reg <= operand_a;
            operand_b_reg <= operand_b;
            opcode_reg <= opcode;
            alu_select_reg <= alu_select;
            enable_reg <= enable;
        end
    end
    
    // ALU0 - Arithmetic Unit Instance
    alu_arithmetic #(
        .WIDTH(DATA_WIDTH)
    ) alu0_inst (
        .a(operand_a_reg),
        .b(operand_b_reg),
        .op(opcode_reg[3:0]),
        .result(alu0_result),
        .carry_out(carry_out_alu0),
        .overflow(overflow_alu0)
    );
    
    // ALU1 - Logic Unit Instance
    alu_logic #(
        .WIDTH(DATA_WIDTH)
    ) alu1_inst (
        .a(operand_a_reg),
        .b(operand_b_reg),
        .op(opcode_reg[3:0]),
        .result(alu1_result),
        .carry_out(carry_out_alu1),
        .overflow(overflow_alu1)
    );
    
    // Result selection based on ALU select or operation type
    assign selected_result = (alu_select_reg == 0) ? alu0_result : alu1_result;
    
    // Flag computation module
    flag_generator #(
        .WIDTH(DATA_WIDTH)
    ) flag_gen_inst (
        .result(selected_result),
        .carry_alu0(carry_out_alu0),
        .overflow_alu0(overflow_alu0),
        .carry_alu1(carry_out_alu1),
        .overflow_alu1(overflow_alu1),
        .alu_select(alu_select_reg),
        .zero_flag(zero_flag),
        .sign_flag(sign_flag),
        .carry_flag(carry_flag),
        .overflow_flag(overflow_flag)
    );
    
    // Output register stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 0;
            flags <= 0;
            valid <= 0;
        end else begin
            if (current_state == EXECUTE) begin
                result <= selected_result;
                flags <= {carry_flag, overflow_flag, sign_flag, zero_flag};
                valid <= 1;
            end else begin
                valid <= 0;
            end
        end
    end
    
    assign busy = (current_state != IDLE);
    
endmodule