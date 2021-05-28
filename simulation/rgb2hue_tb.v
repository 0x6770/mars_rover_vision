`include "rgb2hue.v"

module rgb2hue_tb;

  parameter FIXED = 4;
  parameter PRECISION = 20;

  reg clk = 0;
  reg rst = 1;
  reg [7:0] r, g, b;
  wire [PRECISION-1:0] hue;

  initial begin
    #10 rst <= 0;
    r <= 255;
    g <= 200;
    b <= 100;
    #10 
    r <= 100;
    #10
    r <= 200;
    #10
    g <= 100;
    #10
    r <= 100;
    #10
    r <= 123;
    g <= 234;
    b <= 72;
    #10
    r <= 255;
    g <= 34;
    b <= 123;
    #10
    $finish;
  end

  always #5 clk = !clk;

  rgb2hue #(
    .FIXED(FIXED),
    .PRECISION(PRECISION)
  ) find_hue (
    .clk(clk),
    .hue(hue),
    .r(r),
    .g(g),
    .b(b)
  );

  initial 
    $monitor("At time %t, rgb=%d,%d,%d, hue=%d", $time, r, g, b, hue);

endmodule
