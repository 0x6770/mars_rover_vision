`include "filter.v"
`include "counter.v"
`include "row_buffer.v"

module filter_tb;

  parameter N          = 3;
  parameter DATA_WIDTH = 26;
  parameter LINE_WIDTH = 5;
  parameter ROW_NUMBER = 5;

  reg rst = 1;
  reg clk = 0;
  wire [15:0] x, y;
  wire [DATA_WIDTH-1:0] data_in;
  wire [DATA_WIDTH-1:0] data_out;

  assign data_in = x * y;

  always #5 clk = !clk;

  initial begin
    #10 rst = 0;
    #100
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

  filter #(
    .DATA_WIDTH(DATA_WIDTH),
    .LINE_WIDTH(LINE_WIDTH),
    .N(N)
  ) f (
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
  );

  initial begin
    //$monitor("At time %t, %dx%d=%d, data_out = %b", $time, x, y, data_in, data_out);
  end

endmodule
