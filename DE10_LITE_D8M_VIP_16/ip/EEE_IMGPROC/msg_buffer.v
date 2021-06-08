module msg_buffer (
  input             clk, reset_n,
  input [10:0]      x_min, x_max, y_min, y_max,
  input             eop, in_valid, packet_video,

  input             s_chipselect, s_write, s_read,
  input [3:0]       s_address, 
  input [31:0]      s_writedata, 
  input             read_d,

  //output wire [31:0] s_readdata,
  output reg  [15:0] hue_t, sat_t, val_t,
  output wire [7:0]  msg_buf_size, 
  output wire [31:0] msg_buf_out,
  output reg  [7:0]  reg_status
);

// -- parameters --------------------------------------------------------------
parameter MESSAGE_BUF_MAX = 256;
parameter MSG_INTERVAL    = 6;
parameter BASE            = 0;

// Addresses
`define def_address(ARG) \
   parameter REG_STATUS = ARG*3+0; \
   parameter READ_MSG   = ARG*3+1; \
   parameter HSV_PARAMS = ARG*3+2;

`def_address(BASE)

// -- local variables ---------------------------------------------------------
reg [1:0]   msg_state;
reg [31:0]  msg_buf_in;
//wire [31:0] msg_buf_out;
reg         msg_buf_wr;
wire        msg_buf_rd, msg_buf_flush;
//wire [7:0]  msg_buf_size;
wire        msg_buf_empty;
reg [7:0]   frame_count;

`define RED_BOX_MSG_ID "RBB"

always@(posedge clk) begin
	if (eop & in_valid & packet_video) begin  //Ignore non-video packets
		//Start message writer FSM once every MSG_INTERVAL frames, if there is room in the FIFO
		frame_count <= frame_count - 1;

		if (frame_count == 0 && msg_buf_size < MESSAGE_BUF_MAX-3) begin
			msg_state <= 2'b01;
			frame_count <= MSG_INTERVAL-1;
		end
	end

	//Cycle through message writer states once started
	if (msg_state != 2'b00) msg_state <= msg_state + 2'b01;

end

always@(*) begin	//Write words to FIFO as state machine advances
  case(msg_state)
    2'b00: begin
      msg_buf_in = 32'b0;
      msg_buf_wr = 1'b0;
    end
    2'b01: begin
      msg_buf_in = `RED_BOX_MSG_ID;	//Message ID
      msg_buf_wr = 1'b1;
    end
    2'b10: begin
      msg_buf_in = {5'b0, x_min, 5'b0, y_min};	//Top left coordinate
      msg_buf_wr = 1'b1;
    end
    2'b11: begin
      msg_buf_in = {5'b0, x_max, 5'b0, y_max}; //Bottom right coordinate
      msg_buf_wr = 1'b1;
    end
  endcase
end

// -- Status register bits ----------------------------------------------------
// 31:16 - unimplemented
// 15:8  - number of words in message buffer (read only)
// 7:5   - unused
// 4     - flush message buffer (write only - read as 0)
// 3:0   - unused

// -- Process write -----------------------------------------------------------

always @ (posedge clk)
begin
  if (~reset_n)
    begin
      reg_status <= 8'b0;
      hue_t <= 16'b0;
      sat_t <= 16'b0;
      val_t <= 16'b0;
    end
  else begin
    if (s_chipselect & s_write) begin
      if (s_address == REG_STATUS)	reg_status <= s_writedata[7:0];
      if (s_address == HSV_PARAMS) begin 
        hue_t <= s_writedata[23:14];
        sat_t <= s_writedata[13:07];
        val_t <= s_writedata[06:00];
      end
    end
  end
end

//Flush the message buffer if 1 is written to status register bit 4
assign msg_buf_flush = s_chipselect 
                     & s_write 
                     & (s_address == REG_STATUS) 
                     & s_writedata[4];

// -- Process read ------------------------------------------------------------
//reg read_d;

// Copy the requested word to the output port when there is a read.
//always @ (posedge clk)
//begin
  //if (~reset_n) begin
    //s_readdata <= {32'b0};
    //read_d <= 1'b0;
  //end

  //else if(s_chipselect & s_read) begin
    //if(s_address == REG_STATUS) s_readdata <= {16'b0,msg_buf_size,reg_status};
    //if(s_address == READ_MSG)   s_readdata <= {msg_buf_out};
  //end

  //read_d <= s_read;
//end

//Fetch next word from message buffer after read from READ_MSG
assign msg_buf_rd = s_chipselect
                  & s_read
                  & ~read_d
                  & ~msg_buf_empty
                  & (s_address == READ_MSG);

//Output message FIFO
MSG_FIFO	MSG_FIFO_inst (
  .clock(clk),
  .data(msg_buf_in),
  .rdreq(msg_buf_rd),
  .sclr(~reset_n | msg_buf_flush),
  .wrreq(msg_buf_wr),
  // output
  .q(msg_buf_out),
  .usedw(msg_buf_size),
  .empty(msg_buf_empty)
);

endmodule
