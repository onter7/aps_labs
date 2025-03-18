module CYBERcobra(
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic [15:0] sw_i,
    output logic [31:0] out_o
);

    logic [31:0] pc;    
    logic [31:0] fa_sum;
    logic [31:0] fa_op2;
    logic [31:0] imem_o;
    logic [31:0] alu_res;
    logic        alu_flag;
    logic        rf_we;
    logic [31:0] rf_rd1;
    logic [31:0] rf_rd2;
    logic [31:0] rf_wd;
    logic        fa_sel;
    logic [1:0]  wd_sel;
    
    assign rf_we  = !(imem_o[30] | imem_o[31]);
    assign fa_sel = (alu_flag & imem_o[30]) | imem_o[31];
    assign wd_sel = imem_o[29:28];
    
    always_comb begin
        case (fa_sel)
            1'd0: fa_op2 = 32'd4;
            1'd1: fa_op2 = { {22{imem_o[12]}}, imem_o[12:5], 2'b0 };
        endcase
    end
    
    fulladder32 fa(
        .a_i(pc),
        .b_i(fa_op2),
        .carry_i(1'b0),
        .sum_o(fa_sum)
    );
        
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            pc <= 32'd0;
        end
        else begin
            pc <= fa_sum;
        end
    end
        
    instr_mem imem(
        .read_addr_i(pc),
        .read_data_o(imem_o)
    );
    
    register_file reg_file(
        .clk_i(clk_i),
        .write_enable_i(rf_we),
        .write_addr_i(imem_o[4:0]),
        .read_addr1_i(imem_o[22:18]),
        .read_addr2_i(imem_o[17:13]),
        .write_data_i(rf_wd),
        .read_data1_o(rf_rd1),
        .read_data2_o(rf_rd2)
    );
    
    alu alu(
        .a_i(rf_rd1),
        .b_i(rf_rd2),
        .alu_op_i(imem_o[27:23]),
        .flag_o(alu_flag),
        .result_o(alu_res)
    );
    
    always_comb begin
        case (wd_sel)
            1'd0: rf_wd = { {9{imem_o[27]}}, imem_o[27:5] };
            1'd1: rf_wd = alu_res;
            1'd2: rf_wd = { {16{sw_i[15]}}, sw_i };
            1'd3: rf_wd = 32'd0;
        endcase
    end
    
    assign out_o = rf_rd1;

endmodule