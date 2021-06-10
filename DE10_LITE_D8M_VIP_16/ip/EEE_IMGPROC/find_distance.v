module find_distance(
  input         [10:0] x_min, x_max, y_min, y_max,
  output signed [10:0] x_offset, y_offset,
  output        [19:0] diagonal_sq
);

  // -- define parameters -------------------------------------------------------
  parameter IMAGE_W = 640;
  parameter IMAGE_H = 480;

  // -- local variables ---------------------------------------------------------
  wire [10:0] x_center;
  wire [10:0] y_center;

  wire [10:0] box_w;
  wire [10:0] box_h;

  wire [19:0] box_w_sq;
  wire [19:0] box_h_sq;

  // -- internal wiring ---------------------------------------------------------
  assign box_w    = (x_max-x_min);
  assign box_h    = (y_max-y_min);

  assign box_w_sq = box_w*box_w;
  assign box_h_sq = box_h*box_h;

  assign diagonal_sq = box_w_sq + box_h_sq;

  assign x_center = (x_min+x_max)>>1;
  assign y_center = (y_min+y_max)>>1;

  assign x_offset = (IMAGE_W>>1)-x_center;
  assign y_offset = (IMAGE_H>>1)-y_center;

endmodule
