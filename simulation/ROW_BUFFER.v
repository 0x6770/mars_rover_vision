// -- Buffer the Data required for Filtering ----------------------------------
module ROW_BUFFER #(
  parameter LINE_WIDTH = 640,
  parameter DATA_WIDTH = 26
)(
  input                   rst,
  input                   clk,
  input  [DATA_WIDTH-1:0] data_in,
  output [DATA_WIDTH-1:0] data_out
);

// each line has LINE_WIDTH pixcels, 
// pixcel = {red, green, blue, sop, eop}
reg [DATA_WIDTH-1:0] data [LINE_WIDTH-1:0];

// pass data within line buffers
genvar i;
generate
  for (i = 0; i < LINE_WIDTH-1; i = i + 1) begin : cascade_through
    always @(posedge clk)
      if (~rst)
        data[i+1] <= 0;
      else
        data[i+1] <= data[i];
    end
endgenerate

// input
always @(posedge clk)
	if (~rst)
		data[0] <= 0;
  else
    data[0] <= data_in;

// output
assign data_out = ~rst ? 0 : data[LINE_WIDTH-1];

endmodule
