module CYBERcobra(
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic [15:0] sw_i,
    output logic [31:0] out_o
);

    logic [31:0] pc;    
    logic [31:0] fa_sum;
    logic [31:0] fa_op2;
    logic [31:0] instruction;
    logic [31:0] alu_res;
    logic        alu_flag;
    logic        rf_we;
    logic [31:0] rf_rd1;
    logic [31:0] rf_rd2;
    logic [31:0] rf_wd;
    logic        fa_sel;
    logic [1:0]  wd_sel;
    
    assign rf_we  = !(instruction[30] | instruction[31]);
    assign fa_sel = (alu_flag & instruction[30]) | instruction[31];
    assign wd_sel = instruction[29:28];
    
    always_comb begin
        case (fa_sel)
            1'b0: fa_op2 = 32'd4;
            1'b1: fa_op2 = { {22{instruction[12]}}, instruction[12:5], 2'b0 };
        endcase
    end
    
    fulladder32 fa(
        .a_i(pc),
        .b_i(fa_op2),
        .carry_i(1'b0),
        .sum_o(fa_sum)
    );
        
    always_ff @(posedge clk_i) begin
        if (rst_i) pc <= 32'd0;
        else pc <= fa_sum;
    end
        
    instr_mem imem(
        .read_addr_i(pc),
        .read_data_o(instruction)
    );
    
    register_file reg_file(
        .clk_i(clk_i),
        .write_enable_i(rf_we),
        .write_addr_i(instruction[4:0]),
        .read_addr1_i(instruction[22:18]),
        .read_addr2_i(instruction[17:13]),
        .write_data_i(rf_wd),
        .read_data1_o(rf_rd1),
        .read_data2_o(rf_rd2)
    );
    
    alu alu(
        .a_i(rf_rd1),
        .b_i(rf_rd2),
        .alu_op_i(instruction[27:23]),
        .flag_o(alu_flag),
        .result_o(alu_res)
    );
    
    always_comb begin
        case (wd_sel)
            2'b00: rf_wd = { {9{instruction[27]}}, instruction[27:5] };
            2'b01: rf_wd = alu_res;
            2'b10: rf_wd = { {16{sw_i[15]}}, sw_i };
            2'b11: rf_wd = 32'b0;
        endcase
    end
    
    assign out_o = rf_rd1;

endmodule