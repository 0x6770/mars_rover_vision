module rgb2hue #(
  parameter WIDTH = 16,
  parameter FIXED = 4
)(
  input  logic        clk,
  input  logic        rst,
  input  logic [7:0]  r,
  input  logic [7:0]  g,
  input  logic [7:0]  b,
  output logic [WIDTH-1:0] hsv_h
);

  // find max and min value in RGB
  wire [7:0] cmax;
  wire [7:0] cmin;
  wire [7:0] diff;

  assign cmax = (r >= g) ? ((r >= b) ? r : b) : ((g >= b) ? g : b);
  assign cmin = (r <= g) ? ((r <= b) ? r : b) : ((g <= b) ? g : b);
  assign diff = cmax - cmin;

  // -- find hue by fixed point arithmetics -----------------------------------
  function [WIDTH-1:0] div(
    input logic [WIDTH-1:0] c1, c2
  );
    begin
      div = (((c1-c2)<<(FIXED+FIXED))/(diff<<FIXED));
    end
  endfunction

  always @(posedge clk or posedge rst)
    if (rst)
      hsv_h <= 0;
    else if (diff == 0)
      hsv_h <= 0;
    else
      case(cmax)
        r:
          if (g >= b)
            hsv_h <= (div(g, b)  * (60<<FIXED)) >> FIXED;
          else
            hsv_h <= (360<<FIXED) - ((div(b, g)  * (60<<FIXED)) >> FIXED);
        g:
          if (b >= r)
            hsv_h <= (((2<<FIXED) + div(b, r)) * (60<<FIXED)) >> FIXED;
          else
            hsv_h <= (((2<<FIXED) - div(r, b)) * (60<<FIXED)) >> FIXED;
        b: 
          if (r >= g)
            hsv_h <= (((4<<FIXED) + div(r, g)) * (60<<FIXED)) >> FIXED;
          else
            hsv_h <= (((4<<FIXED) - div(g, r)) * (60<<FIXED)) >> FIXED;
      endcase

endmodule
