module processor_system(
  input  logic        clk_i,
  input  logic        rst_i
);

    logic [31:0] instr_addr;
    logic [31:0] instr;
    logic        mem_req;
    logic        mem_we;
    logic [31:0] mem_wd;
    logic [31:0] mem_addr;
    logic [31:0] mem_rd;
    
    logic        stall;
    
    instr_mem imem(
        .read_addr_i(instr_addr),
        .read_data_o(instr)
    );
    
    processor_core core(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .stall_i(~stall & mem_req),
        .instr_i(instr),
        .mem_rd_i(mem_rd),
        .instr_addr_o(instr_addr),
        .mem_addr_o(mem_addr),
        .mem_req_o(mem_req),
        .mem_we_o(mem_we),
        .mem_wd_o(mem_wd)
    );
    
    data_mem ram(
        .clk_i(clk_i),
        .mem_req_i(mem_req),
        .write_enable_i(mem_we),
        .byte_enable_i(4'b1111),
        .addr_i(mem_addr),
        .write_data_i(mem_wd),
        .read_data_o(mem_rd)
    );
    
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            stall <= 0;
        end
        else begin
            stall <= ~stall & mem_req;
        end
    end

endmodule