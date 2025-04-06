module daisy_chain(
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic [15:0] masked_irq_i,
    input  logic        ready_i,
    input  logic        irq_ret_i,
    output logic [15:0] irq_ret_o,
    output logic [31:0] irq_cause_o,
    output logic        irq_o
);

    logic [15:0] cause;
    logic [15:0] cause_reg;
    logic [15:0] ready;
    
    assign ready[0] = ready_i;
    genvar i;
    generate
        for (i = 0; i < 16; i++) begin
            assign cause[i] = masked_irq_i[i] & ready[i];
            if (i < 15) begin
                assign ready[i+1] = ready[i] & ~(ready[i] & masked_irq_i[i]);
            end
        end
    endgenerate
    
    assign irq_o = |cause;
    assign irq_cause_o = { 12'h800, cause, 4'h0 };
    
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            cause_reg <= 0;
        end
        else begin
            if (irq_o) begin
                cause_reg <= cause;
            end
        end
    end
    
    assign irq_ret_o = irq_ret_i == 0 ? 16'd0 : cause_reg;

endmodule