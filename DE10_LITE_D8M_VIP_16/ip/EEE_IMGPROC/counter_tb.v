`include "counter.v"

module counter_tb;

  parameter ROW_W = 10;
  parameter ROW_N = 3;

  reg clk = 0;
  reg rst = 0;
  wire [15:0] x, y;

  always #5 clk = !clk;

  initial begin
    #10 rst <= 1;
    #120
    $finish;
  end

  counter #(
    .ROW_W(ROW_W),
    .ROW_N(ROW_N)
  ) c (
    .clk(clk),
    .rst(rst),
    .x(x),
    .y(y)
  );

  initial begin
    $monitor("time: %t,%d, x: %d, y: %d", $time, clk, x, y);
  end

endmodule
