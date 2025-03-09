module fulladder4(
    input  logic [3:0] a_i,
    input  logic [3:0] b_i,
    input  logic       carry_i,
    output logic [3:0] sum_o,
    output logic       carry_o
);
    logic carry0;
    logic carry1;
    logic carry2;

    fulladder fulladder0(
        .a_i(a_i[0]),
        .b_i(b_i[0]),
        .carry_i(carry_i),
        .sum_o(sum_o[0]),
        .carry_o(carry0)
    );
    
    fulladder fulladder1(
        .a_i(a_i[1]),
        .b_i(b_i[1]),
        .carry_i(carry0),
        .sum_o(sum_o[1]),
        .carry_o(carry1)
    );
    
    fulladder fulladder2(
        .a_i(a_i[2]),
        .b_i(b_i[2]),
        .carry_i(carry1),
        .sum_o(sum_o[2]),
        .carry_o(carry2)
    );
    
    fulladder fulladder3(
        .a_i(a_i[3]),
        .b_i(b_i[3]),
        .carry_i(carry2),
        .sum_o(sum_o[3]),
        .carry_o(carry_o)
    );

endmodule