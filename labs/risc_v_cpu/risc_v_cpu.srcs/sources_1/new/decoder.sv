module decoder (
  input  logic [31:0]  fetched_instr_i,
  output logic [1:0]   a_sel_o,
  output logic [2:0]   b_sel_o,
  output logic [4:0]   alu_op_o,
  output logic [2:0]   csr_op_o,
  output logic         csr_we_o,
  output logic         mem_req_o,
  output logic         mem_we_o,
  output logic [2:0]   mem_size_o,
  output logic         gpr_we_o,
  output logic [1:0]   wb_sel_o,
  output logic         illegal_instr_o,
  output logic         branch_o,
  output logic         jal_o,
  output logic         jalr_o,
  output logic         mret_o
);
    import decoder_pkg::*;

    logic [6:0]  opcode;
    logic [2:0]  func3;
    logic [6:0]  func7;
    
    localparam ECALL  = 32'h73;
    localparam EBREAK = 32'h100073;
    localparam MRET   = 32'h30200073;

    always_comb begin
        opcode          = fetched_instr_i[6:0];
        func3           = fetched_instr_i[14:12];
        func7           = fetched_instr_i[31:25];
        csr_op_o        = 1'b0;
        csr_we_o        = 1'b0;
        mem_req_o       = 1'b0;
        mem_we_o        = 1'b0;
        gpr_we_o        = 1'b0;
        illegal_instr_o = 1'b0;
        branch_o        = 1'b0;
        jal_o           = 1'b0;
        jalr_o          = 1'b0;
        mret_o          = 1'b0;

        case (opcode)
            {LUI_OPCODE, 2'b11}, {AUIPC_OPCODE, 2'b11}: begin
                a_sel_o  = opcode[6:2] == LUI_OPCODE ? OP_A_ZERO : OP_A_CURR_PC;
                b_sel_o  = OP_B_IMM_U;
                alu_op_o = ALU_ADD;
                wb_sel_o = WB_EX_RESULT;
                gpr_we_o = 1'b1;
            end
            {JAL_OPCODE, 2'b11}: begin
                jal_o = 1'b1;
                a_sel_o  = OP_A_CURR_PC;
                b_sel_o  = OP_B_INCR;
                alu_op_o = ALU_ADD;
                wb_sel_o = WB_EX_RESULT;
                gpr_we_o = 1'b1;
            end
            {JALR_OPCODE, 2'b11}: begin
                if (func3 == 3'b000) begin
                    jalr_o   = 1'b1;
                    a_sel_o  = OP_A_CURR_PC;
                    b_sel_o  = OP_B_INCR;
                    alu_op_o = ALU_ADD;
                    wb_sel_o = WB_EX_RESULT;
                    gpr_we_o = 1'b1;
                end
                else begin
                    illegal_instr_o = 1'b1;
                end
            end
            {BRANCH_OPCODE, 2'b11}: begin
                a_sel_o  = OP_A_RS1;
                b_sel_o  = OP_B_RS2;
                wb_sel_o = WB_EX_RESULT;
                branch_o = 1'b1;
                case (func3)
                    3'b000: alu_op_o = ALU_EQ;
                    3'b001: alu_op_o = ALU_NE;
                    3'b100: alu_op_o = ALU_LTS;
                    3'b101: alu_op_o = ALU_GES;
                    3'b110: alu_op_o = ALU_LTU;
                    3'b111: alu_op_o = ALU_GEU;
                    default: begin
                        illegal_instr_o = 1'b1;
                        branch_o = 1'b0;
                    end                        
                endcase
            end
            {OP_IMM_OPCODE, 2'b11}: begin                    
                a_sel_o = OP_A_RS1;
                b_sel_o = OP_B_IMM_I;
                wb_sel_o = WB_EX_RESULT;
                gpr_we_o = 1'b1;
                case (func3)
                    3'b000: alu_op_o = ALU_ADD;
                    3'b010: alu_op_o = ALU_SLTS;
                    3'b011: alu_op_o = ALU_SLTU;
                    3'b100: alu_op_o = ALU_XOR;
                    3'b110: alu_op_o = ALU_OR;
                    3'b111: alu_op_o = ALU_AND;
                    3'b001, 3'b101: begin
                        case ({func7, func3})
                            10'b0000000001: alu_op_o = ALU_SLL;
                            10'b0000000101: alu_op_o = ALU_SRL;
                            10'b0100000101: alu_op_o = ALU_SRA;
                            default: begin
                                illegal_instr_o = 1'b1;
                                gpr_we_o = 1'b0;
                            end                              
                        endcase
                    end
                endcase                    
            end
            {OP_OPCODE, 2'b11}: begin
                a_sel_o  = OP_A_RS1;
                b_sel_o  = OP_B_RS2;
                wb_sel_o = WB_EX_RESULT;
                gpr_we_o = 1'b1;
                case ({func7, func3})
                    10'b0000000000: alu_op_o = ALU_ADD;
                    10'b0100000000: alu_op_o = ALU_SUB;
                    10'b0000000001: alu_op_o = ALU_SLL;
                    10'b0000000010: alu_op_o = ALU_SLTS;
                    10'b0000000011: alu_op_o = ALU_SLTU;
                    10'b0000000100: alu_op_o = ALU_XOR;
                    10'b0000000101: alu_op_o = ALU_SRL;
                    10'b0100000101: alu_op_o = ALU_SRA;
                    10'b0000000110: alu_op_o = ALU_OR;
                    10'b0000000111: alu_op_o = ALU_AND;
                    default: begin
                        illegal_instr_o = 1'b1;
                        gpr_we_o = 1'b0;
                    end                      
                endcase                    
            end
            {LOAD_OPCODE, 2'b11}: begin
                a_sel_o    = OP_A_RS1;
                b_sel_o    = OP_B_IMM_I;
                alu_op_o   = ALU_ADD;
                mem_req_o  = 1'b1;
                wb_sel_o   = WB_LSU_DATA;
                gpr_we_o   = 1'b1;
                case (func3)
                    3'b000: mem_size_o = LDST_B;
                    3'b001: mem_size_o = LDST_H;
                    3'b010: mem_size_o = LDST_W;
                    3'b100: mem_size_o = LDST_BU;
                    3'b101: mem_size_o = LDST_HU;
                    default: begin
                        illegal_instr_o = 1'b1;
                        mem_req_o  = 1'b0;
                        gpr_we_o   = 1'b0;
                    end              
                endcase    
            end
            {STORE_OPCODE, 2'b11}: begin
                case (func3)
                    LDST_B, LDST_H, LDST_W: begin
                        a_sel_o    = OP_A_RS1;
                        b_sel_o    = OP_B_IMM_S;
                        alu_op_o   = ALU_ADD;
                        mem_req_o  = 1'b1;
                        mem_size_o = func3;
                        mem_we_o   = 1'b1;
                        wb_sel_o   = WB_EX_RESULT;
                    end
                    default: illegal_instr_o = 1'b1;
                endcase
            end
            {SYSTEM_OPCODE, 2'b11}: begin
                case (fetched_instr_i)
                    ECALL, EBREAK: illegal_instr_o = 1'b1;
                    MRET: mret_o = 1'b1;
                    default: begin
                        case (func3)
                            CSR_RW, CSR_RS, CSR_RC, CSR_RWI , CSR_RSI, CSR_RCI: begin
                                csr_op_o = func3;
                                csr_we_o = 1'b1;
                                gpr_we_o = 1'b1;
                                wb_sel_o = WB_CSR_DATA;
                            end
                            default: illegal_instr_o = 1'b1;
                        endcase    
                    end
                endcase                    
            end
            {MISC_MEM_OPCODE, 2'b11}: begin
                if (func3 != 3'b000) illegal_instr_o = 1'b1;
            end
            default: illegal_instr_o = 1'b1;
        endcase
    end

endmodule