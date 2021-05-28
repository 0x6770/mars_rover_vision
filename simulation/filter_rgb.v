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
// pixcel = {red, green, blue, sop, eop}

module filter_rgb #(
  parameter N          = 5,
  parameter NN         = N*N,
  parameter LINE_WIDTH = 640,
  parameter DATA_WIDTH = 26,
  parameter PRECISION  = 16,
  parameter FIXED      = 8
)(
  input  logic                  rst, clk,
  input  logic [DATA_WIDTH-1:0] data_in,
  output logic [DATA_WIDTH-1:0] data_out
);

reg         [DATA_WIDTH-1:0] window          [N-1:0][N-1:0];
reg  signed [PRECISION-1:0]  kernal          [N-1:0][N-1:0];
wire        [DATA_WIDTH-1:0] row_in, row_out [N-1:0];
wire signed [PRECISION-1:0]  r               [NN:0];
wire signed [PRECISION-1:0]  g               [NN:0];
wire signed [PRECISION-1:0]  b               [NN:0];
wire        [PRECISION-1:0]  r_res, g_res, b_res;

assign r[0] = 0;
assign g[0] = 0;
assign b[0] = 0;

assign r_res = r[NN]>0 ? r[NN] : 0;
assign g_res = g[NN]>0 ? g[NN] : 0;
assign b_res = b[NN]>0 ? b[NN] : 0;

// load coefficients
//$readmemb("kernal.mem", kernal);
generate
  initial begin
    if (N==3) begin
      kernal[0][0] = -1; kernal[0][1] = -1; kernal[0][2] = -1;
      kernal[1][0] = -1; kernal[1][1] =  8; kernal[1][2] = -1;
      kernal[2][0] = -1; kernal[2][1] = -1; kernal[2][2] = -1;
    end
    else if (N==5) begin
      kernal[0][0] = -1; kernal[0][1] =  0; kernal[0][2] =  0; kernal[0][3] =  0; kernal[0][4] = -1;
      kernal[1][0] =  0; kernal[1][1] = -1; kernal[1][2] =  0; kernal[1][3] = -1; kernal[1][4] =  0;
      kernal[2][0] =  0; kernal[2][1] =  0; kernal[2][2] =  9; kernal[2][3] =  0; kernal[2][4] =  0;
      kernal[3][0] =  0; kernal[3][1] = -1; kernal[3][2] =  0; kernal[3][3] = -1; kernal[3][4] =  0;
      kernal[4][0] = -1; kernal[4][1] =  0; kernal[4][2] =  0; kernal[4][3] =  0; kernal[4][4] = -1;
    end
  end
endgenerate

// initialise row buffers
genvar i, j;
generate
  for (i = 0; i < N-1; i = i + 1)
    row_buffer #(
      .DATA_WIDTH(DATA_WIDTH),
      .LINE_WIDTH(LINE_WIDTH)
    ) r (
      .clk(clk),
      .rst(rst),
      .data_in(window[i][N-1]),
      .data_out(row_out[i+1])
    );
endgenerate

// move data from row buffer to window
generate
  for (i = 0; i < N-1; i = i + 1)
    always @(posedge clk)
      window[i+1][0] <= row_out[i+1];
endgenerate

// move data within window
generate
  for (i = 0; i < N; i = i + 1)
    for (j = 0; j < N-1; j = j + 1)
      always @(posedge clk)
        if (rst)
          window[i][j+1] <= 0;
        else
          window[i][j+1] <= window[i][j];
endgenerate

// -- input -------------------------------------------------------------------
always @(posedge clk)
  if (rst)
    window[0][0] <= 0;
  else
    window[0][0] <= data_in;

// -- output ------------------------------------------------------------------
always @(posedge clk)
  if (rst)
    data_out <= 0;
  else
    data_out <= {r_res, g_res, b_res, window[0][0][1:0]};
// red
generate
for (i = 0; i < N; i = i + 1)
  for (j = 0; j < N; j = j + 1)
    assign r[i*N+j+1] = r[i*N+j] + window[i][j][25:18]*kernal[i][j];
endgenerate
// green
generate
for (i = 0; i < N; i = i + 1)
  for (j = 0; j < N; j = j + 1)
    assign g[i*N+j+1] = g[i*N+j] + window[i][j][17:10]*kernal[i][j];
endgenerate
// blue
generate
for (i = 0; i < N; i = i + 1)
  for (j = 0; j < N; j = j + 1)
    assign b[i*N+j+1] = b[i*N+j] + window[i][j][9:2]*kernal[i][j];
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
  $display(
    {
      "========================================\n",
      "kernal\n",
      "========================================\n",
      "|00: %d, |01: %d, |02: %d\n",
      "|10: %d, |11: %d, |12: %d\n",
      "|20: %d, |21: %d, |22: %d\n"
    },
    kernal[0][0], kernal[0][1], kernal[0][2], 
    kernal[1][0], kernal[1][1], kernal[1][2],
    kernal[2][0], kernal[2][1], kernal[2][2]
  );
end

endmodule
