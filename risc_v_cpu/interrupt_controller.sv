module interrupt_controller(
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        exception_i,
  input  logic        irq_req_i,
  input  logic        mie_i,
  input  logic        mret_i,

  output logic        irq_ret_o,
  output logic [31:0] irq_cause_o,
  output logic        irq_o
);

    logic exc_h;
    logic irq_h;
    logic set_exc;
    logic set_irq;
    logic reset_exc;
    logic reset_irq;
    
    logic irq;
    
    assign set_exc = exception_i | exc_h;
    assign set_irq = irq | irq_h;
    assign reset_exc = mret_i;
    assign reset_irq = reset_exc & ~set_exc;
    
    always_ff @(posedge clk_i) begin
        if (rst_i) exc_h <= 0;
        else exc_h <= ~reset_exc & set_exc;
    end
    
    always_ff @(posedge clk_i) begin
        if (rst_i) irq_h <= 0;
        else irq_h <= ~reset_irq & set_irq;
    end
    
    assign irq = (irq_req_i & mie_i) & ~(set_exc | irq_h);
    
    daisy_chain daisy_chain(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .masked_irq_i(irq_req_i & mie_i),
        .irq_ret_i(mret_i & ~(set_exc)),
        .ready_i(~(set_exc | irq_h)),
        .irq_ret_o(irq_ret_o),
        .irq_cause_o(irq_cause_o),
        .irq_o(irq_o)
    );

endmodule