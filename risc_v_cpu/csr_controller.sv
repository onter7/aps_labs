module csr_controller(

  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        trap_i,

  input  logic [ 2:0] opcode_i,

  input  logic [11:0] addr_i,
  input  logic [31:0] pc_i,
  input  logic [31:0] mcause_i,
  input  logic [31:0] rs1_data_i,
  input  logic [31:0] imm_data_i,
  input  logic        write_enable_i,

  output logic [31:0] read_data_o,
  output logic [31:0] mie_o,
  output logic [31:0] mepc_o,
  output logic [31:0] mtvec_o
);

    import csr_pkg::*;
    
    logic [31:0] operation;
    logic [ 4:0] enable;
    logic [31:0] csr_read_value;
    
    logic [31:0] mie_reg;
    logic [31:0] mtvec_reg;
    logic [31:0] mscratch_reg;
    logic [31:0] mepc_reg;
    logic [31:0] mcause_reg;
    
    assign mie_o   = mie_reg;
    assign mtvec_o = mtvec_reg;
    assign mepc_o  = mepc_reg;

    assign enable[0] = write_enable_i & (addr_i == MIE_ADDR);
    assign enable[1] = write_enable_i & (addr_i == MTVEC_ADDR);
    assign enable[2] = write_enable_i & (addr_i == MSCRATCH_ADDR);
    assign enable[3] = write_enable_i & (addr_i == MEPC_ADDR);
    assign enable[4] = write_enable_i & (addr_i == MCAUSE_ADDR);

    always_comb begin        
        case (addr_i)
            MIE_ADDR      : csr_read_value = mie_reg;
            MTVEC_ADDR    : csr_read_value = mtvec_reg;
            MSCRATCH_ADDR : csr_read_value = mscratch_reg;
            MEPC_ADDR     : csr_read_value = mepc_reg;
            MCAUSE_ADDR   : csr_read_value = mcause_reg;
            default       : csr_read_value = 32'b0;
        endcase
    end

    always_comb begin
        case (opcode_i)
            CSR_RW  : operation =  rs1_data_i;
            CSR_RS  : operation =  rs1_data_i | csr_read_value;
            CSR_RC  : operation = ~rs1_data_i & csr_read_value;
            CSR_RWI : operation =  imm_data_i;
            CSR_RSI : operation =  imm_data_i | csr_read_value;
            CSR_RCI : operation = ~imm_data_i & csr_read_value;
            default : operation = 32'b0;
        endcase
    end
    
    assign read_data_o = csr_read_value;
    
    always_ff @(posedge clk_i) begin
        if (rst_i) mie_reg <= 32'b0;
        else if (enable[0]) mie_reg <= operation;
    end
    
    always_ff @(posedge clk_i) begin
        if (rst_i) mtvec_reg <= 32'b0;
        else if (enable[1]) mtvec_reg <= operation;
    end
    
    always_ff @(posedge clk_i) begin
        if (rst_i) mscratch_reg <= 32'b0;
        else if (enable[2]) mscratch_reg <= operation;
    end
    
    always_ff @(posedge clk_i) begin
        if (rst_i) mepc_reg <= 32'b0;
        else if (enable[3] || trap_i) mepc_reg <= trap_i ? pc_i : operation;
    end
    
    always_ff @(posedge clk_i) begin
        if (rst_i) mcause_reg <= 32'b0;
        else if (enable[4] || trap_i) mcause_reg <= trap_i ? mcause_i : operation;
    end

endmodule