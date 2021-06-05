// -- Filtering with 3x3 window -----------------------------------------------
//
//                        0   1   3   4   ...  N-1
//
//                      +---+---+---+---+ ... +---+
//        data_in => 0  |   |   |   |   | ... |   |
//                      +---+---+---+---+ ... +---+
// window[0][N-1] => 1  |   |   |   |   | ... |   |
//                      +---+---+---+---+ ... +---+
// window[1][N-1] => 2  |   |   |   |
//                      +---+---+---+ 

module filter_conv #(
  parameter ROW_W     = 640,
  parameter DATA_W    = 9,
  parameter PRECISION = 16
)(
  input                      rst, clk, in_valid,
  input      [PRECISION-1:0] data_in,
  output reg [DATA_W-1:0]    data_out
);

// each row has LINE_WIDTH elements, 
reg        [PRECISION-1:0] row    [ROW_W*2+3-1:0];
reg signed [PRECISION-1:0] kernal [2:0][2:0];
wire       [PRECISION-1:0] temp;

integer i, j;
//// initialise kernal
//initial begin
  //for (i = 0; i < 3; i = i + 1) begin : kernal_row
    //for (j = 0; j < 3; j = j + 1) begin : kernal_col
      //kernal[i][j] = 16'b11101; // 0.111 using 8bit fixed point notation
    //end
  //end
//end

// pass data within row buffer
always @(posedge clk) begin
  for (i = 0; i < ROW_W*2+3-1; i = i + 1) begin : iterate_pixcels
    if (~rst)
      row[i+1] <= 0;
    else if (in_valid)
      row[i+1] <= row[i];
  end
end

// -- input -------------------------------------------------------------------
always @(posedge clk) begin
  if (~rst)
    row[0] <= 0;
  else if (in_valid)
    row[0] <= data_in;
end

// -- output ------------------------------------------------------------------
always @(posedge clk)
  if (~rst)
    data_out <= 0;
  else
    //data_out <= row[100];
    data_out <= temp>>4;
// sumation
assign temp = (row[0])
            + (row[1]<<1)
            + (row[2])
            + (row[ROW_W+0]<<1)
            + (row[ROW_W+1]<<2)
            + (row[ROW_W+2]<<1)
            + (row[(ROW_W<<1)+0])
            + (row[(ROW_W<<1)+1]<<1)
            + (row[(ROW_W<<1)+2]);

initial begin
  $monitor(
    {
      "time: %t, data_in: %d\n",
      "-----------------------------------------------------------------\n",
      "|00: %d, |01: %d, |02: %d\n",
      "|10: %d, |11: %d, |12: %d\n",
      "|20: %d, |21: %d, |22: %d\n",
      "data_out: %d\n"
    },
    $time, data_in,
    row[0],         row[1],         row[2], 
    row[ROW_W+0],   row[ROW_W+1],   row[ROW_W+2],
    row[2*ROW_W+0], row[2*ROW_W+1], row[2*ROW_W+2],
    data_out
  );
  //$display(
    //{
      //"========================================\n",
      //"kernal\n",
      //"========================================\n",
      //"|00: %d, |01: %d, |02: %d\n",
      //"|10: %d, |11: %d, |12: %d\n",
      //"|20: %d, |21: %d, |22: %d\n"
    //},
    //kernal[0][0], kernal[0][1], kernal[0][2], 
    //kernal[1][0], kernal[1][1], kernal[1][2],
    //kernal[2][0], kernal[2][1], kernal[2][2]
  //);
end

endmodule
