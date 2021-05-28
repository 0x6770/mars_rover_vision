module counter #(
  parameter LINE_WIDTH = 640,
  parameter ROW_NUMBER = 480
)(
  input logic clk,
  input logic rst,
  output logic [15:0] x, y
);

  always @(posedge clk or posedge rst)
    if (rst || (x == LINE_WIDTH-1))
      x <= 0;
    else
      x <= x + 1;

  always @(posedge clk or posedge rst)
    if (rst)
      y <= 0;
    else if (x == LINE_WIDTH-1)
      if (y == ROW_NUMBER-1)
        y <= 0;
      else
        y <= y + 1;

endmodule
