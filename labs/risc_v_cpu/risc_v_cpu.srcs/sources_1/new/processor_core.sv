module processor_core (
  input  logic        clk_i,
  input  logic        rst_i,

  input  logic        stall_i,
  input  logic [31:0] instr_i,
  input  logic [31:0] mem_rd_i,

  output logic [31:0] instr_addr_o,
  output logic [31:0] mem_addr_o,
  output logic [ 2:0] mem_size_o,
  output logic        mem_req_o,
  output logic        mem_we_o,
  output logic [31:0] mem_wd_o
);

    logic [31:0] imm_I;
    logic [31:0] imm_U;
    logic [31:0] imm_S;
    logic [31:0] imm_B;
    logic [31:0] imm_J;
    
    assign imm_I = { {20{instr_i[31]}}, instr_i[31:20] };
    assign imm_U = { instr_i[31:12],    {12{1'b0}} };
    assign imm_S = { {20{instr_i[31]}}, instr_i[31:25], instr_i[11:7] };
    assign imm_B = { {19{instr_i[31]}}, instr_i[31],    instr_i[7],     instr_i[30:25], instr_i[11:8],  1'b0 };
    assign imm_J = { {11{instr_i[31]}}, instr_i[31],    instr_i[19:12], instr_i[20],    instr_i[30:21], 1'b0 };
    
    logic [31:0] pc;    
    assign instr_addr_o = pc;
    
    logic        jalr_o;
    logic        jal_o;
    logic        branch_o;
    logic        gpr_we_o;
    logic [1:0]  wb_sel_o;
    logic [4:0]  alu_op_o;
    logic [1:0]  a_sel_o;
    logic [2:0]  b_sel_o;
    
    logic [31:0] rd1_o;
    logic [31:0] rd2_o;
    logic [31:0] rf_wb_data;
    
    assign mem_wd_o = rd2_o;
    
    logic [31:0] alu_a_in;
    logic [31:0] alu_b_in;        
    logic        main_alu_flag;
    logic [31:0] main_alu_res;
    assign mem_addr_o = main_alu_res;
    
    logic [31:0] pc_add;
    logic [31:0] pc_adder_o;    
    logic [31:0] jalr_adder_o;
    
    logic        jal_branch_flag;    
    assign jal_branch_flag = jal_o | (main_alu_flag & branch_o);
    
    logic        reg_file_we;
    assign reg_file_we = gpr_we_o & ~stall_i;

    decoder decoder(
        .fetched_instr_i(instr_i),
        .a_sel_o(a_sel_o),
        .b_sel_o(b_sel_o),
        .alu_op_o(alu_op_o),
        .mem_req_o(mem_req_o),
        .mem_we_o(mem_we_o),
        .mem_size_o(mem_size_o),
        .gpr_we_o(gpr_we_o),
        .wb_sel_o(wb_sel_o),
        .branch_o(branch_o),
        .jal_o(jal_o),
        .jalr_o(jalr_o)        
    );
    
    register_file reg_file(
        .clk_i(clk_i),
        .write_enable_i(reg_file_we),
        .write_addr_i(instr_i[11:7]),
        .read_addr1_i(instr_i[19:15]),
        .read_addr2_i(instr_i[24:20]),
        .write_data_i(rf_wb_data),
        .read_data1_o(rd1_o),
        .read_data2_o(rd2_o)
    );
    
    always_comb begin
        case (a_sel_o)
            0: alu_a_in = rd1_o;
            1: alu_a_in = pc;
            2: alu_a_in = 0;
        endcase
        
        case (b_sel_o)
            0: alu_b_in = rd2_o;
            1: alu_b_in = imm_I;
            2: alu_b_in = imm_U;
            3: alu_b_in = imm_S;
            4: alu_b_in = 4;
        endcase
        
        case (wb_sel_o)
            0: rf_wb_data = main_alu_res;
            1: rf_wb_data = mem_rd_i; 
        endcase
        
        case (jal_branch_flag)
            0: pc_add = 4;
            1: pc_add = branch_o == 0 ? imm_J : imm_B;
        endcase
    end
    
    alu main_alu(
        .a_i(alu_a_in),
        .b_i(alu_b_in),
        .alu_op_i(alu_op_o),
        .flag_o(main_alu_flag),
        .result_o(main_alu_res)
    );
    
    fulladder32 pc_adder(
        .a_i(pc),
        .b_i(pc_add),
        .carry_i(1'b0),
        .sum_o(pc_adder_o)    
    );
    
    fulladder32 jalr_adder(
        .a_i(rd1_o),
        .b_i(imm_I),
        .carry_i(1'b0),
        .sum_o(jalr_adder_o)
    );
    
    always_ff @(posedge clk_i) begin
        if (rst_i == 1'b1) begin
            pc <= 0;
        end
        else if (stall_i == 1'b0) begin
            case (jalr_o)
                0: pc <= pc_adder_o;
                1: pc <= { jalr_adder_o[31:1], 1'b0 };
            endcase
        end
    end

endmodule