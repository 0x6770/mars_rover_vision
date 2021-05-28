`include "row_buffer.v"
`include "counter.v"
`include "filter_hsv.v"
`include "rgb2hue.v"

module filter_hsv_image_tb;

  parameter N          = 3;
  parameter FIXED      = 4;
  parameter DATA_WIDTH = 26;
  parameter PRECISION  = 16;
  parameter LINE_WIDTH = 640;
  parameter ROW_NUMBER = 480;
  parameter INFILE     = "image_sd.bin";
  parameter OUTFILE    = "image_sd_hsv.out";

  integer               fd;
  reg                   rst = 1;
  reg                   clk = 0;
  wire [15:0]           x, y;
  wire [DATA_WIDTH-1:0] data_out, data_in;
  wire [7:0]            r, g, b;
  wire [PRECISION-1:0]  hue;
  reg  [DATA_WIDTH-1:0] memory [ROW_NUMBER-1:0][LINE_WIDTH-1:0];

  assign data_in = memory[y][x];
  assign r       = data_in[25:17];
  assign g       = data_in[17:10];
  assign b       = data_in[09:02];

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

  rgb2hue #(
    .FIXED(FIXED),
    .PRECISION(PRECISION)
  ) find_hue (
    .rst(rst),
    .clk(clk),
    .hue(hue),
    .r({8'b0,r}),
    .g({8'b0,g}),
    .b({8'b0,b})
  );

  counter #(
    .LINE_WIDTH(LINE_WIDTH),
    .ROW_NUMBER(ROW_NUMBER)
  ) c (
    .clk(clk),
    .rst(rst),
    .x(x),
    .y(y)
  );

  filter_hsv #(
    .DATA_WIDTH(DATA_WIDTH),
    .LINE_WIDTH(LINE_WIDTH),
    .PRECISION(PRECISION),
    .N(N)
  ) f_rgb (
    .clk(clk),
    .rst(rst),
    .data_in(hue),
    .data_out(data_out)
  );

  always @(posedge clk) begin
    if (!rst) begin
      $fwrite(fd, hue);

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
    //$monitor("At time %t, [%d,%d] = %h, %d,%d,%d, hue = %d", $time, x, y, data_in, r, g, b, hue);
  end

endmodule
