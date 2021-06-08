module EEE_IMGPROC(
	// global clock & reset
	input clk,
	input reset_n,
	
  // mm slave
  input							s_chipselect,
  input							s_read,
  input             s_write,
  output reg [31:0] s_readdata,
  input      [31:0] s_writedata,
  input      [3:0]  s_address,

  // streaming sink
  input	[23:0] sink_data,
  input        sink_valid,
  output       sink_ready,
  input        sink_sop,
  input        sink_eop,

  // streaming source
  output [23:0] source_data,
  output        source_valid,
  input         source_ready,
  output        source_sop,
  output        source_eop,

  // conduit export
  input mode,
  output [31:0] disp
);

assign disp = hue_t[0];

// -- Parameter Deffinition ---------------------------------------------------
parameter IMAGE_W         = 11'd640;
parameter IMAGE_H         = 11'd480;
parameter MESSAGE_BUF_MAX = 256;
parameter MSG_INTERVAL    = 10;
parameter BB_COL_DEFAULT  = 24'h00ff00;
parameter N_COLOR         = 5;

integer i;
genvar j;

wire [7:0] red, green, blue, grey;
wire [7:0] red_out, green_out, blue_out;
wire       sop, eop, in_valid, out_ready;

// Find boundary of cursor box

// Highlight detected areas
wire detect_res_all;
assign detect_res_all = detect_res[0] | detect_res[1]
                      | detect_res[2] | detect_res[3] 
                      | detect_res[4];

assign grey = green[7:1] + red[7:2] + blue[7:2]; //Grey = green/2 + red/4 + blue/4

wire [23:0] color [N_COLOR-1:0];
wire [23:0] color_high;

assign color[0] = 24'hff_00_00; // red
assign color[1] = 24'hff_b6_c1; // pink
assign color[2] = 24'hff_ff_00; // yellow
assign color[3] = 24'h00_ff_00; // green
assign color[4] = 24'h00_00_ff; // blue

assign color_high = detect_res[0] ? color[0] :
                    detect_res[1] ? color[1] :
                    detect_res[2] ? color[2] :
                    detect_res[3] ? color[3] :
                    detect_res[4] ? color[4] : {grey, grey, grey};

// Show bounding box
wire [23:0]        new_image;
wire [N_COLOR-1:0] bb_active;
wire               bb_active_all;

generate
  for (j=0; j<N_COLOR; j=j+1) begin : border_for_each_color
    assign bb_active[j] = (x == left[j]) | (x == right[j]) | (y == top[j]) | (y == bottom[j]);
  end
endgenerate

assign bb_active_all = bb_active[0] | bb_active[1] | bb_active[2]
                     | bb_active[3] | bb_active[4];

assign new_image = bb_active[0] ? color[0]
                 : bb_active[1] ? color[1]
                 : bb_active[2] ? color[2]
                 : bb_active[3] ? color[3]
                 : bb_active[4] ? color[4]
                 : color_high;

// Switch output pixels depending on mode switch
// Don't modify the start-of-packet word - it's a packet discriptor
// Don't modify data in non-video packets
assign {red_out, green_out, blue_out} = (mode & ~sop & packet_video) ? new_image : {red,green,blue};

//Count valid pixels to tget the image coordinates. Reset and detect packet type on Start of Packet.
reg [10:0] x, y;
reg        packet_video;
always@(posedge clk) begin
	if (sop) begin
		x <= 11'h0;
		y <= 11'h0;
		packet_video <= (blue[3:0] == 3'h0);
	end
	else if (in_valid) begin
		if (x == IMAGE_W-1) begin
			x <= 11'h0;
			y <= y + 11'h1;
		end
		else begin
			x <= x + 11'h1;
		end
	end
end

//Find first and last red pixels
reg [10:0] x_min [N_COLOR-1:0];
reg [10:0] y_min [N_COLOR-1:0];
reg [10:0] x_max [N_COLOR-1:0];
reg [10:0] y_max [N_COLOR-1:0];

always@(posedge clk) begin
  for (i=0; i<N_COLOR; i=i+1) begin : find_min_max_for_each_color
    if (detect_res[i] & in_valid) begin	//Update bounds when the pixel is red
      if (x < x_min[i]) x_min[i] <= x;
      if (x > x_max[i]) x_max[i] <= x;
      if (y < y_min[i]) y_min[i] <= y;
      y_max[i] <= y;
    end
    if (sop & in_valid) begin	//Reset bounds on start of packet
      x_min[i] <= IMAGE_W-11'h1;
      x_max[i] <= 0;
      y_min[i] <= IMAGE_H-11'h1;
      y_max[i] <= 0;
    end
  end
end

//Process bounding box at the end of the frame.
reg [10:0] left        [N_COLOR-1:0];
reg [10:0] right       [N_COLOR-1:0];
reg [10:0] top         [N_COLOR-1:0];
reg [10:0] bottom      [N_COLOR-1:0];
reg [7:0]  frame_count [N_COLOR-1:0];
always@(posedge clk) begin
	if (eop & in_valid & packet_video) begin  //Ignore non-video packets
    for (i=0; i<N_COLOR; i=i+1) begin : latch_edges
      //Latch edges for display overlay on next frame
      left[i]   <= x_min[i];
      right[i]  <= x_max[i];
      top[i]    <= y_min[i];
      bottom[i] <= y_max[i];
    end
  end
end
	
//Generate output messages for CPU
reg [31:0]  msg_buf_in    [N_COLOR-1:0];
wire [31:0] msg_buf_out   [N_COLOR-1:0];
reg         msg_buf_wr    [N_COLOR-1:0];
wire        msg_buf_rd    [N_COLOR-1:0];
wire        msg_buf_flush [N_COLOR-1:0];
wire [7:0]  msg_buf_size  [N_COLOR-1:0];
wire        msg_buf_empty [N_COLOR-1:0];
wire [7:0]  reg_status    [N_COLOR-1:0];


// -- Detect Target Color -----------------------------------------------------
wire [N_COLOR-1:0] detect_res;
reg  [15:0] hue, sat, val; // hue [0-360]
reg  [15:0] hue_t [N_COLOR-1:0];
reg  [15:0] sat_t [N_COLOR-1:0];
reg  [15:0] val_t [N_COLOR-1:0];

generate
  for (j=0; j<N_COLOR; j=j+1) begin : detect_colors
    assign detect_res[j] = ((hue+15'd360) > (hue_t[j]+15'd350))
                         & ((hue+15'd360) < (hue_t[j]+15'd370))
                         & (sat > sat_t[j])
                         & (val > val_t[j]);
  end
endgenerate

wire [7:0] red_filt, green_filt, blue_filt;

// Moving Average
filter_conv #(
  .ROW_W(IMAGE_W)
) filt_r (
  .rst(reset_n),
  .clk(clk),
  .in_valid(in_valid),
  .data_in(red),
  .data_out(red_filt)
);

filter_conv #(
  .ROW_W(IMAGE_W)
) filt_g (
  .rst(reset_n),
  .clk(clk),
  .in_valid(in_valid),
  .data_in(green),
  .data_out(green_filt)
);

filter_conv #(
  .ROW_W(IMAGE_W)
) filt_b (
  .rst(reset_n),
  .clk(clk),
  .in_valid(in_valid),
  .data_in(blue),
  .data_out(blue_filt)
);

// RGB to Hue
rgb2hsv h1 (
  .clk(clk),
  .rst(reset_n),
  .red(red_filt),
  .green(green_filt),
  .blue(blue_filt),
  .hue(hue),
  .sat(sat),
  .val(val)
);

//Streaming registers to buffer video signal
STREAM_REG #(.DATA_WIDTH(26)) in_reg (
	.clk(clk),
	.rst_n(reset_n),
	.ready_out(sink_ready),
	.valid_out(in_valid),
	.data_out({red,green,blue,sop,eop}),
	.ready_in(out_ready),
	.valid_in(sink_valid),
	.data_in({sink_data,sink_sop,sink_eop})
);

STREAM_REG #(.DATA_WIDTH(26)) out_reg (
	.clk(clk),
	.rst_n(reset_n),
	.ready_out(out_ready),
	.valid_out(source_valid),
	.data_out({source_data,source_sop,source_eop}),
	.ready_in(source_ready),
	.valid_in(in_valid),
	.data_in({red_out, green_out, blue_out, sop, eop})
);

// Addresses
`define RED    0
`define PINK   3
`define YELLOW 6
`define GREEN  9
`define BLUE   12
`define msg_address(color) color+2;

reg read_d;

generate
  for (j=0; j<N_COLOR; j=j+1) begin : generate_msg_buffer
    msg_buffer #(
      .BASE(j)
    ) msg_buf (
      .clk(clk), 
      .reset_n(reset_n),
      .x_min(x_min[j]), 
      .x_max(x_max[j]), 
      .y_min(y_min[j]), 
      .y_max(y_max[j]),
      .eop(eop), 
      .in_valid(in_valid), 
      .packet_video(packet_video),
      .read_d(read_d),

      .s_chipselect(s_chipselect), 
      .s_write(s_write), 
      .s_read(s_read),
      .s_address(s_address), 
      .s_writedata(s_writedata), 

      // outputs
      .hue_t(hue_t[j]),
      .sat_t(sat_t[j]), 
      .val_t(val_t[j]),

      .msg_buf_size(msg_buf_size[j]),
      .msg_buf_out(msg_buf_out[j]),
      .reg_status(reg_status[j])
);

  end
endgenerate

`define REG_STATUS(BASE) BASE*3+0
`define READ_MSG(BASE)   BASE*3+1
`define HSV_PARAMS(BASE) BASE*3+2

always @ (posedge clk) begin
  if (~reset_n) begin
    s_readdata <= {32'b0};
    read_d <= 1'b0;
  end
  else if(s_chipselect & s_read) begin
    for (i=0; i<N_COLOR; i=i+1) begin : read_form_msg_buf
      if(s_address == `REG_STATUS(i)) s_readdata <= {16'b0,msg_buf_size[i],reg_status[i]};
      if(s_address == `READ_MSG(i))   s_readdata <= {msg_buf_out[i]};
    end
  end
  read_d <= s_read;
end

endmodule
