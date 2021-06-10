module counter #(
  parameter ROW_W = 640,
  parameter ROW_N = 480
)(
  input               clk, rst,
  output logic [15:0] x, y
);

  always @(posedge clk or negedge rst)
    if ((!rst) || (x == ROW_W-1))
      x <= 0;
    else
      x <= x + 1;

  always @(posedge clk or negedge rst)
    if (!rst)
      y <= 0;
    else if (x == ROW_W-1)
      if (y == ROW_N-1)
        y <= 0;
      else
        y <= y + 1;

endmodule
