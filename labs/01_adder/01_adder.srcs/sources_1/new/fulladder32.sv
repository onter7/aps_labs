module fulladder32(
    input  logic [31:0] a_i,
    input  logic [31:0] b_i,
    input  logic        carry_i,
    output logic [31:0] sum_o,
    output logic        carry_o
);

    logic carry0;
    logic carry1;
    logic carry2;
    logic carry3;
    logic carry4;
    logic carry5;
    logic carry6;
    
    fulladder4 fulladder4_0(
        .a_i(a_i[3:0]),
        .b_i(b_i[3:0]),
        .carry_i(carry_i),
        .sum_o(sum_o[3:0]),
        .carry_o(carry0)
    );
    
    fulladder4 fulladder4_1(
        .a_i(a_i[7:4]),
        .b_i(b_i[7:4]),
        .carry_i(carry0),
        .sum_o(sum_o[7:4]),
        .carry_o(carry1)
    );
    
    fulladder4 fulladder4_2(
        .a_i(a_i[11:8]),
        .b_i(b_i[11:8]),
        .carry_i(carry1),
        .sum_o(sum_o[11:8]),
        .carry_o(carry2)
    );
    
    fulladder4 fulladder4_3(
        .a_i(a_i[15:12]),
        .b_i(b_i[15:12]),
        .carry_i(carry2),
        .sum_o(sum_o[15:12]),
        .carry_o(carry3)
    );
    
    fulladder4 fulladder4_4(
        .a_i(a_i[19:16]),
        .b_i(b_i[19:16]),
        .carry_i(carry3),
        .sum_o(sum_o[19:16]),
        .carry_o(carry4)
    );
    
    fulladder4 fulladder4_5(
        .a_i(a_i[23:20]),
        .b_i(b_i[23:20]),
        .carry_i(carry4),
        .sum_o(sum_o[23:20]),
        .carry_o(carry5)
    );
    
    fulladder4 fulladder4_6(
        .a_i(a_i[27:24]),
        .b_i(b_i[27:24]),
        .carry_i(carry5),
        .sum_o(sum_o[27:24]),
        .carry_o(carry6)
    );
    
    fulladder4 fulladder4_7(
        .a_i(a_i[31:28]),
        .b_i(b_i[31:28]),
        .carry_i(carry6),
        .sum_o(sum_o[31:28]),
        .carry_o(carry_o)
    );

endmodule