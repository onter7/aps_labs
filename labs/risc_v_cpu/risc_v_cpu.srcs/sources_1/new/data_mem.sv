module data_mem
import memory_pkg::DATA_MEM_SIZE_BYTES;
import memory_pkg::DATA_MEM_SIZE_WORDS;
(
  input  logic        clk_i,
  input  logic        mem_req_i,
  input  logic        write_enable_i,
  input  logic [ 3:0] byte_enable_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] write_data_i,
  output logic [31:0] read_data_o,
  output logic        ready_o
);
    localparam int ADDR_WIDTH = $clog2(DATA_MEM_SIZE_BYTES);

    logic [31:0] ram [DATA_MEM_SIZE_WORDS];    
        
    assign ready_o = 1'b1;
    
    always_ff @(posedge clk_i) begin
        if (mem_req_i) begin
            if (write_enable_i) begin
                if (byte_enable_i[0]) ram[addr_i[ADDR_WIDTH-1:2]][7:0]   <= write_data_i[7:0];
                if (byte_enable_i[1]) ram[addr_i[ADDR_WIDTH-1:2]][15:8]  <= write_data_i[15:8];
                if (byte_enable_i[2]) ram[addr_i[ADDR_WIDTH-1:2]][23:16] <= write_data_i[23:16];
                if (byte_enable_i[3]) ram[addr_i[ADDR_WIDTH-1:2]][31:24] <= write_data_i[31:24];
            end
            else begin
                read_data_o <= ram[addr_i[ADDR_WIDTH-1:2]];
            end 
        end
    end

endmodule