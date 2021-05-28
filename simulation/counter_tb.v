`include "counter.v"

module counter_tb;

  parameter LINE_WIDTH = 10;
  parameter ROW_NUMBER = 3;

  reg clk = 0;
  reg rst = 1;
  wire [15:0] x, y;

  always #5 clk = !clk;

  initial begin
    #10 rst <= 0;
    #120
    $finish;
  end

  counter #(
    .LINE_WIDTH(LINE_WIDTH),
    .ROW_NUMBER(ROW_NUMBER)
  ) c (
    .clk(clk),
    .rst(rst),
    .x(x),
    .y(y)
  );

  initial begin
    $monitor("time: %t, x: %d, y: %d", $time, x, y);
  end

endmodule
