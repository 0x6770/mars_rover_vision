module rgb2hue #(
  parameter PRECISION = 16,
  parameter FIXED = 4
)(
  input  logic                 clk, rst,
  input  logic [PRECISION-1:0] r, g, b,
  output logic [PRECISION-1:0] hue = 0 // [0, 360]
);

  // find max and min value in RGB
  wire [PRECISION-1:0] cmax, cmin, diff;

  assign cmax = (r >= g) ? ((r >= b) ? r : b) : ((g >= b) ? g : b);
  assign cmin = (r <= g) ? ((r <= b) ? r : b) : ((g <= b) ? g : b);
  assign diff = cmax - cmin;

  // -- find hue by fixed point arithmetics -----------------------------------
  function [PRECISION-1:0] div(
    input logic [PRECISION-1:0] c1, c2
  );
    begin
      div = (((c1-c2)<<(FIXED+FIXED))/(diff<<FIXED));
    end
  endfunction

  always @(posedge clk) begin
    if (rst) begin 
      hue <= 0;
    end
    else if (diff == 0) begin
      hue <= 0;
    end
    else begin
      case(cmax)
        r:
          if (g >= b)
            hue <= (div(g, b)*(60<<FIXED))>>FIXED>>FIXED;
          else
            hue <= ((360<<FIXED)-((div(b, g)*(60<<FIXED))>>FIXED))>>FIXED;
        g:
          if (b >= r)
            hue <= ((((2<<FIXED)+div(b, r))*(60<<FIXED))>>FIXED)>>FIXED;
          else
            hue <= ((((2<<FIXED)-div(r, b))*(60<<FIXED))>>FIXED)>>FIXED;
        b: 
          if (r >= g)
            hue <= ((((4<<FIXED)+div(r, g))*(60<<FIXED))>>FIXED)>>FIXED;
          else
            hue <= ((((4<<FIXED)-div(g, r))*(60<<FIXED))>>FIXED)>>FIXED;
      endcase
    end
  end

  initial begin
    $monitor("%t %d %d", $time, clk, hue);
  end

endmodule
