`include "mov_avg.v"

module mov_avg_tb();

reg         clk = 1;
reg         rst = 1;
reg  [10:0] x   = 0;
wire [10:0] x_avg;

always #5 clk = !clk;
always #5 x   = x+1;

initial begin
  #5 rst <= 0;
  #5 rst <= 1; x <=1;
  #400 $finish;
end

mov_avg #(
  .BIT(4)
) ma (
  .clk(clk),
  .rst(rst),
  .x(x),
  .x_avg(x_avg)
);

initial begin 
  $monitor("%t, x: %03d, x_avg: %03d", $time, x, x_avg);
end

endmodule
