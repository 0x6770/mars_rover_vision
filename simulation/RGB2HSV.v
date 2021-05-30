module RGB2HSV (
  input             clk, rst,
  input      [7:0]  red, green, blue,
  output reg [7:0]  hue, saturation, value
);

  // find max and min value in RGB
  wire [15:0] cmax, cmin, diff, r, g, b;
  assign r = {8'b0, red};
  assign g = {8'b0, green};
  assign b = {8'b0, blue};

  assign cmax = (r > g) ? ((r > b) ? r : b) : ((g > b) ? g : b);
  assign cmin = (r < g) ? ((r < b) ? r : b) : ((g < b) ? g : b);
  assign diff = cmax - cmin;

  // -- find hue by fixed point arithmetics -----------------------------------
  function [15:0] div(
    input [15:0] c1, c2
  );
    begin
      div = (((c1-c2)<<8)/(diff<<4));
    end
  endfunction

  always @(posedge clk) begin
    if (~rst) begin 
      hue        <= 0;
      saturation <= 0;
      value      <= 0;
    end
    else if (diff == 0) begin
      hue        <= 0;
      saturation <= 0;
      value      <= cmax[7:0];
    end
    else begin
      saturation <= (((diff<<8)/(cmax<<4))*(100<<4))>>4;
      value      <= cmax[7:0];
      case(cmax)
        r:
          if (g >= b)
            hue <= (div(g, b)*(16'd60<<4))>>8;
          else
            hue <= ((16'd360<<4)-((div(b, g)*(16'd60<<4))>>4))>>4;
        g:
          if (b >= r)
            hue <= ((((16'd2<<4)+div(b, r))*(16'd60<<4))>>4)>>4;
          else
            hue <= ((((16'd2<<4)-div(r, b))*(16'd60<<4))>>4)>>4;
        b: 
          if (r >= g)
            hue <= ((((16'd4<<4)+div(r, g))*(16'd60<<4))>>4)>>4;
          else
            hue <= ((((16'd4<<4)-div(g, r))*(16'd60<<4))>>4)>>4;
      endcase
    end
  end

  //initial begin
    //$monitor("%t %d %d", $time, clk, hue);
  //end

endmodule
