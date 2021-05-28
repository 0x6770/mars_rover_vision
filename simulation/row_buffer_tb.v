`include "row_buffer.v"
`include "counter.v"

module row_buffer_tb;

  parameter DATA_WIDTH = 26;
  parameter LINE_WIDTH = 640;

  reg rst = 0;
  reg clk = 0;
  wire [DATA_WIDTH-1:0] res;
  wire [DATA_WIDTH-1:0] data_out;

  always #5 clk = !clk;

  initial begin
    #10 rst = 0;
    #10 rst = 1;
    #10 rst = 0;
    #10000 $finish;
  end

  counter #(.DATA_WIDTH(DATA_WIDTH)) c (
    .clk(clk),
    .rst(rst),
    .res(res)
  );

  row_buffer #(
    .DATA_WIDTH(DATA_WIDTH),
    .LINE_WIDTH(LINE_WIDTH)
  ) r (
    .clk(clk),
    .rst(rst),
    .data_in(res),
    .data_out(data_out)
  );

  initial begin
    $monitor("At time %t, data_in = %d, data_out = %d", $time, res, data_out);
  end

endmodule
