`include "ROW_BUFFER.v"
`include "counter.v"
`include "FILTER_CONV.v"
`include "RGB2HSV.v"

module filter_grey_image_tb;

  parameter N          = 3;
  parameter FIXED      = 8;
  parameter DATA_WIDTH = 26;
  parameter PRECISION  = 31;
  parameter LINE_WIDTH = 640;
  parameter ROW_NUMBER = 480;
  parameter INFILE     = "image_sd.bin";
  parameter OUTFILE    = "image_sd_CONV.out";

  integer               fd;
  reg                   rst = 1;
  reg                   clk = 0;
  wire [15:0]           x, y;
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

  wire [7:0] red, green, blue, grey;
  wire [7:0] red_f, green_f, blue_f, grey_f;
  wire [7:0] red_out, green_out, blue_out;
  wire       sop, eop, in_valid, out_ready;

  assign {red,green,blue} = data_in[25:2];

  // -- Detect Target Color -----------------------------------------------------
  wire [15:0] upper, lower, margin, target;

  assign target = 16'd 113;
  assign margin = 16'd 20;
  assign upper  = 16'd 360 + target + margin;
  assign lower  = 16'd 360 + target - margin;

  function detect(
    input [15:0] h,s,v
  );
    begin
      detect = ((h+16'd 360)>lower) && ((h+16'd 360)<upper) && (s>50);
    end
  endfunction

  // Find boundary of cursor box

  // Highlight detected areas
  wire [23:0] red_high;
  wire [7:0]  hue, saturation, value;
  assign grey = green[7:1] + red[7:2] + blue[7:2]; //Grey = green/2 + red/4 + blue/4
  //assign red_high  =  red_detect ? {8'hff, 8'h0, 8'h0} : {grey, grey, grey};

  counter #(
    .LINE_WIDTH(LINE_WIDTH),
    .ROW_NUMBER(ROW_NUMBER)
  ) c (
    .clk(clk),
    .rst(rst),
    .x(x),
    .y(y)
  );

  FILTER_CONV #(
    .LINE_WIDTH(LINE_WIDTH)
  ) f_conv_r (
    .clk(clk),
    .rst(~rst),
    .data_in(red),
    .data_out(red_f)
  );

  FILTER_CONV #(
    .LINE_WIDTH(LINE_WIDTH)
  ) f_conv_g (
    .clk(clk),
    .rst(~rst),
    .data_in(green),
    .data_out(green_f)
  );

  FILTER_CONV #(
    .LINE_WIDTH(LINE_WIDTH)
  ) f_conv_b (
    .clk(clk),
    .rst(~rst),
    .data_in(blue),
    .data_out(blue_f)
  );

  always @(posedge clk) begin
    if (!rst) begin
      if (detect(hue,saturation,value))
        $fwrite(fd, red, ",", "green", ",", blue);
      else 
        $fwrite(fd, grey, ",", grey, ",", grey);
      //if (y == 100) begin
      if ((y == ROW_NUMBER-1) && (x == LINE_WIDTH-1)) begin
        $display("done");
        $finish;
      end
      else begin
        $fwrite(fd, ",");
      end
    end
  end


  initial begin
    //$monitor("At time %t, [%d,%d] = %h, %d,%d,%d, hue = %d", $time, x, y, data_in, r, g, b, hue);
  end

endmodule
