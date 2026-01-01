// rtl/fifo_sync.sv
// Synchronous FIFO with ready/valid handshake
// - push when in_valid && in_ready
// - pop  when out_valid && out_ready
//
// Notes:
// - DEPTH must be power of 2 (for pointer wrap).
// - out_data is a combinational read of mem[rptr] (simple & robust for simulation demos).

module fifo_sync #(
  parameter int WIDTH = 32,
  parameter int DEPTH = 16
)(
  input  logic              clk,
  input  logic              rst_n,

  // Input side
  input  logic              in_valid,
  output logic              in_ready,
  input  logic [WIDTH-1:0]  in_data,

  // Output side
  output logic              out_valid,
  input  logic              out_ready,
  output logic [WIDTH-1:0]  out_data,

  // Optional status
  output logic              full,
  output logic              empty,
  output logic [$clog2(DEPTH+1)-1:0] count
);

  localparam int ADDR_W = $clog2(DEPTH);

  initial begin
    if ((DEPTH & (DEPTH - 1)) != 0) begin
      $error("DEPTH must be power of 2 for fifo_sync (DEPTH=%0d).", DEPTH);
    end
  end

  logic [WIDTH-1:0] mem [0:DEPTH-1];
  logic [ADDR_W-1:0] wptr, rptr;

  logic push, pop;

  assign empty    = (count == 0);
  assign full     = (count == DEPTH[$bits(count)-1:0]);

  assign in_ready  = ~full;
  assign out_valid = ~empty;

  assign push = in_valid && in_ready;
  assign pop  = out_valid && out_ready;

  // Combinational head data (valid when out_valid=1)
  assign out_data = mem[rptr];

  // Write pointer + memory write
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wptr <= '0;
    end else if (push) begin
      mem[wptr] <= in_data;
      wptr <= wptr + 1'b1;
    end
  end

  // Read pointer advance
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rptr <= '0;
    end else if (pop) begin
      rptr <= rptr + 1'b1;
    end
  end

  // Count management
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      count <= '0;
    end else begin
      unique case ({push, pop})
        2'b10: count <= count + 1'b1; // push only
        2'b01: count <= count - 1'b1; // pop only
        default: count <= count;      // no change or push+pop
      endcase
    end
  end

endmodule
