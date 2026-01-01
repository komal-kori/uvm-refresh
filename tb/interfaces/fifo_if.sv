interface fifo_if #(parameter int WIDTH = 32) (input logic clk);
  logic rst_n;

  logic in_valid;
  logic in_ready;
  logic [WIDTH-1:0] in_data;

  logic out_valid;
  logic out_ready;
  logic [WIDTH-1:0] out_data;

endinterface
