`include "row_buffer.v"
`include "counter.v"
`include "filter_rgb.v"

module filter_rgb_image_tb;

  parameter N          = 3;
  parameter DATA_WIDTH = 26;
  parameter PRECISION  = 16;
  parameter LINE_WIDTH = 640;
  parameter ROW_NUMBER = 480;
  parameter INFILE     = "image_sd.bin";
  parameter OUTFILE    = "image_sd_rgb.out";

  integer               fd;
  reg                   rst = 1;
  reg                   clk = 0;
  wire [15:0]           x, y;
  wire [DATA_WIDTH-1:0] data_out;
  wire [DATA_WIDTH-1:0] data_in;
  reg  [DATA_WIDTH-1:0] memory [ROW_NUMBER-1:0][LINE_WIDTH-1:0];

  assign data_in = memory[y][x];

  initial begin
    $readmemb(INFILE, memory);
    fd = $fopen(OUTFILE, "w"); // overwrite
  end

  always #5 clk = !clk;

  initial begin
    #10 rst = 0;
    #10000000
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

  filter_rgb #(
    .DATA_WIDTH(DATA_WIDTH),
    .LINE_WIDTH(LINE_WIDTH),
    .PRECISION(PRECISION),
    .N(N)
  ) f (
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
  );

  always @(posedge clk) begin
    if (!rst) begin
      $fwrite(fd, data_out[25:18], ",");
      $fwrite(fd, data_out[17:10], ",");
      $fwrite(fd, data_out[09:02]);

      //if (y == 100) begin
      if ((y == ROW_NUMBER-1) && (x == LINE_WIDTH-1)) begin
        $display("done");
        $finish;
      end
      else begin
        $fwrite(fd, ";");
      end
    end
  end


  initial begin
    //$monitor("At time %t, [%d,%d] = %h, data_out = %b", $time, x, y, data_in, data_out);
  end

endmodule
