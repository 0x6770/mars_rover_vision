`include "filter_conv.v"
`include "counter.v"

module filter_tb;

  parameter DATA_W = 9;
  parameter ROW_W  = 50;
  parameter ROW_N  = 50;

  reg rst = 0;
  reg clk = 0;
  wire [15:0] x, y;
  wire [DATA_W-1:0] data_in;
  wire [DATA_W-1:0] data_out;
  wire              in_valid;

  assign in_valid = 1;

  assign data_in = x+ROW_W*y;

  always #5 clk = !clk;

  initial begin
    #10 rst <= 1;
    #2000
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

  filter_conv #(
    .DATA_W(DATA_W),
    .ROW_W(ROW_W)
  ) f (
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid),
    .data_in(data_in),
    .data_out(data_out)
  );

endmodule
