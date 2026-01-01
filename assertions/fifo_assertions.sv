// assertions/fifo_assertions.sv
module fifo_assertions #(parameter int DEPTH = 16) (
  input logic clk,
  input logic rst_n,
  input logic in_valid,
  input logic in_ready,
  input logic out_valid,
  input logic out_ready,
  input logic [$clog2(DEPTH+1)-1:0] count
);

  // No overflow: cannot accept push when full
  property p_no_overflow;
    @(posedge clk) disable iff(!rst_n)
      (count == DEPTH) |-> !in_ready;
  endproperty
  assert property (p_no_overflow);

  // No underflow: out_valid must be low when empty
  property p_no_underflow;
    @(posedge clk) disable iff(!rst_n)
      (count == 0) |-> !out_valid;
  endproperty
  assert property (p_no_underflow);

  // Count never exceeds DEPTH
  property p_count_range;
    @(posedge clk) disable iff(!rst_n)
      count <= DEPTH;
  endproperty
  assert property (p_count_range);

endmodule
