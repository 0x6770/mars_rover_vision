`include "rgb2hsv.v"

module rgb2hue_tb;

  parameter FIXED      = 8;
  parameter PRECISION  = 32;
  parameter DATA_WIDTH = 8;

  reg clk = 0;
  reg rst = 0;
  reg [DATA_WIDTH-1:0] r, g, b;
  wire [DATA_WIDTH:0] hue, sat, val; // hue [0-360]

  initial begin
    #10 rst <= 1;
    {r, g, b} <= {8'd 255, 8'd 200, 8'd 100};

    #10 
    {r, g, b} <= {8'd 100, 8'd 200, 8'd 100};

    #10
    {r, g, b} <= {8'd 200, 8'd 200, 8'd 100};

    #10
    {r, g, b} <= {8'd 200, 8'd 100, 8'd 100};

    #10
    {r, g, b} <= {8'd 100, 8'd 100, 8'd 100};

    #10
    {r, g, b} <= {8'd 123, 8'd 234, 8'd  72};

    #10
    {r, g, b} <= {8'd 255, 8'd  34, 8'd 123};

    #10
    {r, g, b} <= {8'd  17, 8'd  21, 8'd  26};

    #10
    $finish;
  end

  always #5 clk = !clk;

  rgb2hsv find_hue (
    .clk(clk),
    .rst(rst),
    .hue(hue),
    .sat(sat),
    .val(val),
    .red(r),
    .green(g),
    .blue(b)
  );


  initial begin
    $monitor("At time %t, rgb=%d,%d,%d, hue=%d, sat=%d, val=%d", 
              $time, r, g, b, hue, sat, val);
  end

endmodule
