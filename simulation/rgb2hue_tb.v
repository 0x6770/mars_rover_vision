module rgb2hue_tb;

  parameter FIXED = 4;
  parameter WIDTH = 20;

  reg clk = 0;
  reg rst = 0;
  reg [7:0] r, g, b;
  wire [WIDTH-1:0] hue_fp; 
  wire [WIDTH-1:0] hue = hue_fp >> FIXED;

  initial begin
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
    .WIDTH(WIDTH)
  ) find_hue (
    .clk(clk),
    .hsv_h(hue_fp),
    .r(r),
    .g(g),
    .b(b)
  );

  initial 
    $monitor("At time %t,  rgb=%d,%d,%d,  clk=%b,  hue_fp=%b, hue=%d", $time, r, g, b, clk, hue_fp, hue);

endmodule
