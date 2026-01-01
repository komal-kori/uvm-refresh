module top_tb;

  localparam int WIDTH = 32;
  localparam int DEPTH = 16;

  logic clk;
  fifo_if #(WIDTH) vif(clk);

  // DUT
  fifo_sync #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut (
    .clk       (clk),
    .rst_n     (vif.rst_n),
    .in_valid  (vif.in_valid),
    .in_ready  (vif.in_ready),
    .in_data   (vif.in_data),
    .out_valid (vif.out_valid),
    .out_ready (vif.out_ready),
    .out_data  (vif.out_data),
    .full      (),
    .empty     (),
    .count     ()
  );

  // Clock
  initial clk = 0;
  always #5 clk = ~clk;

  // Simple reference model queue
  logic [WIDTH-1:0] q[$];

  // Reset
  initial begin
    vif.rst_n = 0;
    vif.in_valid = 0;
    vif.in_data  = '0;
    vif.out_ready = 0;
    repeat (5) @(posedge clk);
    vif.rst_n = 1;
  end

  // Stimulus + checking
  initial begin
    wait(vif.rst_n);

    // Basic scenario: push 10, pop 10
    vif.out_ready = 1;

    for (int i = 0; i < 10; i++) begin
      drive_push(i);
    end

    // Allow pops
    repeat (30) @(posedge clk);

    // Random traffic burst
    for (int cyc = 0; cyc < 200; cyc++) begin
      vif.in_valid  <= ($urandom_range(0,1));
      vif.in_data   <= $urandom();
      vif.out_ready <= ($urandom_range(0,1));

      @(posedge clk);

      // Update reference model based on handshake
      if (vif.in_valid && vif.in_ready) begin
        q.push_back(vif.in_data);
      end
      if (vif.out_valid && vif.out_ready) begin
        if (q.size() == 0) begin
          $fatal(1, "UNDERFLOW in reference model: DUT popped when queue empty.");
        end
        logic [WIDTH-1:0] exp = q.pop_front();
        if (vif.out_data !== exp) begin
          $fatal(1, "DATA MISMATCH: exp=%h got=%h", exp, vif.out_data);
        end
      end
    end

    $display("TEST PASSED");
    $finish;
  end

  task drive_push(input logic [WIDTH-1:0] val);
    // Drive a single push with backpressure-aware handshake
    vif.in_valid <= 1;
    vif.in_data  <= val;
    do @(posedge clk); while (!vif.in_ready);
    // accepted on this cycle
    q.push_back(val);
    vif.in_valid <= 0;
  endtask

endmodule
