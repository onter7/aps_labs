module processor_system(
  input  logic        clk_i,
  input  logic        rst_i
);

    logic [31:0] instr_addr;
    logic [31:0] instr;
    logic        core_lsu_req;
    logic        lsu_dm_req;
    logic        core_lsu_we;
    logic        lsu_dm_we;
    logic [2:0]  core_lsu_size;
    logic [3:0]  lsu_dm_be;
    logic [31:0] core_lsu_wd;
    logic [31:0] lsu_dm_wd;
    logic [31:0] core_lsu_addr;
    logic [31:0] lsu_dm_addr;
    logic [31:0] lsu_core_rd;
    logic [31:0] dm_lsu_rd;    
    logic        stall;
    logic        ready;
    logic        irq_req;
    logic        irq_ret;
    
    instr_mem imem(
        .read_addr_i(instr_addr),
        .read_data_o(instr)
    );
    
    processor_core core(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .stall_i(stall),
        .instr_i(instr),
        .mem_rd_i(lsu_core_rd),
        .irq_req_i(irq_req),
        .instr_addr_o(instr_addr),
        .mem_addr_o(core_lsu_addr),
        .mem_req_o(core_lsu_req),
        .mem_we_o(core_lsu_we),
        .mem_wd_o(core_lsu_wd),
        .mem_size_o(core_lsu_size),
        .irq_ret_o(irq_ret)
    );
    
    data_mem ram(
        .clk_i(clk_i),
        .mem_req_i(lsu_dm_req),
        .write_enable_i(lsu_dm_we),
        .byte_enable_i(lsu_dm_be),
        .addr_i(lsu_dm_addr),
        .write_data_i(lsu_dm_wd),
        .read_data_o(dm_lsu_rd),
        .ready_o(ready)
    );
    
    lsu lsu(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .core_req_i(core_lsu_req),
        .core_we_i(core_lsu_we),
        .core_size_i(core_lsu_size),
        .core_addr_i(core_lsu_addr),
        .core_wd_i(core_lsu_wd),
        .core_rd_o(lsu_core_rd),
        .core_stall_o(stall),
        .mem_req_o(lsu_dm_req),
        .mem_we_o(lsu_dm_we),
        .mem_be_o(lsu_dm_be),
        .mem_addr_o(lsu_dm_addr),
        .mem_wd_o(lsu_dm_wd),
        .mem_rd_i(dm_lsu_rd),
        .mem_ready_i(ready)
    );

endmodule