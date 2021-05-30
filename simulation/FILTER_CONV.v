// -- Filtering with NxN window -----------------------------------------------
//
//                                NxN window
//                             0   1  ... N-2 N-1
//                           +---+---+---+---+---+
//            data_in =>  0  |   |   |   |   |   | => ri[0] => rb[0]
//                           +---+---+---+---+---+
//     rb[0] => ro[0] =>  1  |   |   |   |   |   | => ri[1] => rb[1]
//                           +---+---+---+---+---+ 
//     rb[1] => ro[1] => ... |   |   |   |   |   |    ...
//                           +---+---+---+---+---+ 
//                ...    N-2 |   |   |   |   |   | => ri[N-1] => rb[N-1]
//                           +---+---+---+---+---+ 
// rb[N-2] => ro[N-2] => N-1 |   |   |   |   |   | => data_out
//                           +---+---+---+---+---+ 

module FILTER_CONV #(
  parameter N          = 3,
  parameter NN         = N*N,
  parameter LINE_WIDTH = 640,
  parameter PRECISION  = 31,
  parameter FIXED      = 8
)(
  input                      rst, clk,
  input      [PRECISION-1:0] data_in,
  output reg [PRECISION-1:0] data_out
);

reg        [PRECISION-1:0] window           [N-1:0][N-1:0];
reg signed [PRECISION-1:0] kernal           [N-1:0][N-1:0];
wire       [PRECISION-1:0] row_in, row_out  [N-1:0];
wire       [PRECISION-1:0] temp             [NN:0];

genvar i, j;
integer m, n;
// initialise kernal
generate
  initial begin
    for (m = 0; m < N; m = m + 1) begin : kernal_row
      for (n = 0; n < N; n = n + 1) begin : kernal_col
        kernal[m][n] = 31'b11100; // 0.111 using 8bit fixed point notation
      end
    end
  end
endgenerate

// initialise row buffers
generate
  for (i = 0; i < N-1; i = i + 1) begin : row_buffer_init
    ROW_BUFFER #(
      .LINE_WIDTH(LINE_WIDTH)
    ) r (
      .clk(clk),
      .rst(rst),
      .data_in(window[i][N-1]),
      .data_out(row_out[i+1])
    );
    end
endgenerate

// move data from row buffer to window
generate
  for (i = 0; i < N-1; i = i + 1) begin : row_buffer_out
    always @(posedge clk)
      window[i+1][0] <= row_out[i+1];
  end
endgenerate

// move data within window
generate
  for (i = 0; i < N; i = i + 1) begin : window_row
    for (j = 0; j < N-1; j = j + 1) begin : window_col
      always @(posedge clk)
        if (~rst)
          window[i][j+1] <= 0;
        else
          window[i][j+1] <= window[i][j];
      end
    end
endgenerate

// -- input -------------------------------------------------------------------
always @(posedge clk)
  if (~rst)
    window[0][0] <= 0;
  else
    window[0][0] <= data_in;

// -- output ------------------------------------------------------------------
always @(posedge clk)
  if (~rst)
    data_out <= 0;
  else
    data_out <= temp[NN]>>FIXED;
// sumation
generate
  for (i = 0; i < N; i = i + 1) begin : sum_row
    for (j = 0; j < N; j = j + 1) begin : sum_col
      assign temp[i*N+j+1] = temp[i*N+j] + 
                             (((window[i][j]<<FIXED)*kernal[i][j])>>FIXED);
    end
  end
endgenerate

initial begin
  //$monitor(
    //{
      //"time: %t\n",
      //"-----------------------------------------------------------------\n",
      //"                 |00: %d, |01: %d, |02: %d\n",
      //"ro1: %d => |10: %d, |11: %d, |12: %d\n",
      //"ro2: %d => |20: %d, |21: %d, |22: %d\n",
      //"data_out: %d\n"
    //},
    //$time,      window[0][0], window[0][1], window[0][2], 
    //row_out[1], window[1][0], window[1][1], window[1][2],
    //row_out[2], window[2][0], window[2][1], window[2][2],
    //data_out
  //);
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
