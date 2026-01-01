// rtl/fifo_sync.sv
// Simple synchronous FIFO with ready/valid style handshake.
// - push when in_valid && in_ready
// - pop  when out_valid && out_ready
//
// Parameters:
//   WIDTH: data width
//   DEPTH: FIFO depth (must be power of 2 for this implementation)
// Notes:
//   - Uses simple memory array + read/write pointers + count.
//   - out_data is registered (updated on pop or when becoming valid).

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

  // Basic checks (synth tools may ignore $error; still useful for simulation)
  initial begin
    if ((DEPTH & (DEPTH - 1)) != 0) begin
      $error("DEPTH must be power of 2 for fifo_sync (DEPTH=%0d).", DEPTH);
    end
  end

  logic [WIDTH-1:0] mem [0:DEPTH-1];
  logic [ADDR_W-1:0] wptr, rptr;

  // Handshake decisions
  logic push, pop;

  assign empty    = (count == 0);
  assign full     = (count == DEPTH[$bits(count)-1:0]);

  assign in_ready = ~full;
  assign out_valid = ~empty;

  assign push = in_valid && in_ready;
  assign pop  = out_valid && out_ready;

  // Write logic
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wptr <= '0;
    end else begin
      if (push) begin
        mem[wptr] <= in_data;
        wptr <= wptr + 1'b1;
      end
    end
  end

  // Read data path: update out_data when popping OR when FIFO transitions from empty to non-empty
  // This keeps out_data meaningful when out_valid is high.
  logic [WIDTH-1:0] mem_rdata;

  assign mem_rdata = mem[rptr];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rptr     <= '0;
      out_data <= '0;
    end else begin
      // If we are about to present first valid data after empty, preload out_data.
      // Also update out_data on pop to next element.
      if (!empty && (pop)) begin
        rptr <= rptr + 1'b1;
        // next cycle out_data should reflect new rptr; we preload from mem_rdata now.
        out_data <= mem[rptr + 1'b1];
      end else if (empty && push) begin
        // FIFO was empty and we push: that item becomes immediately readable next cycle.
        // Preload out_data with pushed data for clean behavior.
        out_data <= in_data;
      end else if (!empty && !pop) begin
        // Hold out_data stable when not popping.
        out_data <= out_data;
      end
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
