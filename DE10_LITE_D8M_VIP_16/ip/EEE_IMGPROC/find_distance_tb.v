`include "find_distance.v"

module find_distance_tb();

reg         [10:0] x_min, x_max;
reg         [10:0] y_min, y_max;
wire signed [10:0] x_offset;
wire signed [10:0] y_offset;
wire        [19:0] diagonal_sq;

initial begin
  #5 {x_min, x_max, y_min, y_max} <= {11'd000, 11'd010, 11'd000, 11'd010};
  #5 {x_min, x_max, y_min, y_max} <= {11'd010, 11'd020, 11'd010, 11'd020};
  #5 {x_min, x_max, y_min, y_max} <= {11'd020, 11'd030, 11'd020, 11'd030};
end

find_distance fd (
  .x_min(x_min),
  .x_max(x_max),
  .y_min(y_min),
  .y_max(y_max),
  .x_offset(x_offset),
  .y_offset(y_offset),
  .diagonal_sq(diagonal_sq)
);

initial begin
  $monitor("%t, x: %03d, y: %03d, d: %03d", $time, x_offset, y_offset, diagonal_sq);
end

endmodule
