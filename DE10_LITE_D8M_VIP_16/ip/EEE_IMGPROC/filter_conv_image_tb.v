`include "rgb2hsv.v"
`include "counter.v"
`include "filter_conv.v"

module MY_IMGPROC_tb;

  parameter DATA_W     = 26;
  parameter PRECISION  = 32;
  parameter ROW_W      = 640;
  parameter ROW_N      = 480;
  parameter INFILE     = "image.bin";
  parameter OUTFILE    = "image.out";

  integer     fd;
  reg         rst = 0;
  reg         clk = 0;
  wire [9:0]  x,y;
  reg  [23:0] memory [ROW_N-1:0][ROW_W-1:0];
  wire [7:0]  red, green, blue;
  wire [7:0]  red_out, green_out, blue_out;
  wire        in_valid;

  assign in_valid = 1;
  assign {red,green,blue} = memory[y][x];

  initial begin
    $readmemb(INFILE, memory);
    fd = $fopen(OUTFILE, "w"); // overwrite
  end

  always #5 clk = !clk;

  initial begin
    #10 rst <= 1;
    #100000000
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

  // Convolution Filter
  filter_conv #(
    .ROW_W(ROW_W)
  ) filter_red (
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid),
    .data_in(red),
    .data_out(red_out)
  );

  filter_conv #(
    .ROW_W(ROW_W)
  ) filter_green (
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid),
    .data_in(green),
    .data_out(green_out)
  );

  filter_conv #(
    .ROW_W(ROW_W)
  ) filter_blue (
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid),
    .data_in(blue),
    .data_out(blue_out)
  );

  always @(posedge clk) begin
    if (rst) begin
      $fwrite(fd, red_out, ",", green_out, ",", blue_out);

      //if (y == 100) begin
      if (x==(ROW_W-1) && y==(ROW_N-1)) begin
        $display("done");
        $finish;
      end
      else begin
        $fwrite(fd, ";");
      end
    end
  end

  initial begin
    //$monitor("At time %t, $d, %d,%d,%d", $time, cnt, red_out, green_out, blue_out);
  end

endmodule
