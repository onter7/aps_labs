module lsu(
  input logic clk_i,
  input logic rst_i,

  // Интерфейс с ядром
  input  logic        core_req_i,
  input  logic        core_we_i,
  input  logic [ 2:0] core_size_i,
  input  logic [31:0] core_addr_i,
  input  logic [31:0] core_wd_i,
  output logic [31:0] core_rd_o,
  output logic        core_stall_o,

  // Интерфейс с памятью
  output logic        mem_req_o,
  output logic        mem_we_o,
  output logic [ 3:0] mem_be_o,
  output logic [31:0] mem_addr_o,
  output logic [31:0] mem_wd_o,
  input  logic [31:0] mem_rd_i,
  input  logic        mem_ready_i
);
    import decoder_pkg::*;
    
    logic [1:0] byte_offset;
    logic       half_offset;
    logic       stall;

    assign mem_addr_o = core_addr_i;
    assign mem_req_o = core_req_i;
    assign mem_we_o = core_we_i;
    
    assign byte_offset = core_addr_i[1:0];
    assign half_offset = core_addr_i[1];
    
    always_comb begin
        case (core_size_i)
            LDST_W: mem_be_o = 4'b1111;
            LDST_H, LDST_HU: mem_be_o = half_offset == 0 ? 4'b0011 : 4'b1100;
            LDST_B, LDST_BU: mem_be_o = 4'b0001 << byte_offset;
        endcase
        
        case (core_size_i)
            LDST_W: core_rd_o = mem_rd_i;
            LDST_B: begin
                case (byte_offset)
                    2'b00: core_rd_o = { {24{mem_rd_i[7]}}, mem_rd_i[7:0] };
                    2'b01: core_rd_o = { {24{mem_rd_i[15]}}, mem_rd_i[15:8] };
                    2'b10: core_rd_o = { {24{mem_rd_i[23]}}, mem_rd_i[23:16] };
                    2'b11: core_rd_o = { {24{mem_rd_i[31]}}, mem_rd_i[31:24] };
                endcase
            end
            LDST_BU: begin
                case (byte_offset)
                    2'b00: core_rd_o = { {24{1'b0}}, mem_rd_i[7:0] };
                    2'b01: core_rd_o = { {24{1'b0}}, mem_rd_i[15:8] };
                    2'b10: core_rd_o = { {24{1'b0}}, mem_rd_i[23:16] };
                    2'b11: core_rd_o = { {24{1'b0}}, mem_rd_i[31:24] };
                endcase
            end
            LDST_H: begin
                case (half_offset)
                    1'b0: core_rd_o = { {16{mem_rd_i[15]}}, mem_rd_i[15:0] };
                    1'b1: core_rd_o = { {16{mem_rd_i[31]}}, mem_rd_i[31:16] };
                endcase
            end
            LDST_HU: begin
                case (half_offset)
                    1'b0: core_rd_o = { {16{1'b0}}, mem_rd_i[15:0] };
                    1'b1: core_rd_o = { {16{1'b0}}, mem_rd_i[31:16] };
                endcase
            end
        endcase
        
        case (core_size_i)
            LDST_H, LDST_HU: mem_wd_o = { {2{core_wd_i[15:0]}} };
            LDST_W: mem_wd_o = core_wd_i;
            LDST_B, LDST_BU: mem_wd_o = { {4{core_wd_i[7:0]}} };
        endcase
    end
    
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            stall <= 1'b0;
        end
        else begin
            stall <= ~(stall & mem_ready_i) & core_req_i;
        end
        core_stall_o <= ~(stall & mem_ready_i) & core_req_i;
    end

endmodule