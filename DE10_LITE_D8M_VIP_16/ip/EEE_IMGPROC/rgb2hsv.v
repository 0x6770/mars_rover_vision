module rgb2hsv (
  input                   clk, rst,
  input  [7:0] red, green, blue, 
  output [8:0] hue, sat, val     // hue [0-360]
  );

// -- internal wiring ---------------------------------------------------------
  reg  [31:0] hue_f, sat_f, val_f;
  wire [31:0] cmax, cmin, diff;
  wire [31:0] r, g, b;

  // restore output from fixed point representation
  assign hue = hue_f>>4;
  assign sat = sat_f>>4;
  assign val = val_f>>4;

  // transform input into fixed point representation
  assign r = red   <<4;
  assign g = green <<4;
  assign b = blue  <<4;

  // find max and min val_f in RGB
  assign cmax = (r>=g) ? ((r>=b) ? r : b) : ((g>=b) ? g : b);
  assign cmin = (r<=g) ? ((r<=b) ? r : b) : ((g<=b) ? g : b);
  assign diff = cmax - cmin;

  always @(posedge clk) begin
    if (~rst) begin 
      hue_f <= 0;
      sat_f <= 0;
      val_f <= 0;
    end
    else begin
      if (diff == 0) begin
        hue_f <= 0;
        sat_f <= 0;
        val_f <= cmax;
      end
      else begin
        sat_f <= (diff*(100<<4))/cmax;
        val_f <= (cmax*(100<<4))/(255<<4);
        case(cmax)
          r:
            if (g>=b)
              hue_f <= ((60<<4)*(g-b))/diff;
            else
              hue_f <= (360<<4)-(((60<<4)*(b-g))/diff);
          g:
            if (b >= r)
              hue_f <= (120<<4)+(((60<<4)*(b-r))/diff);
            else
              hue_f <= (120<<4)-(((60<<4)*(r-b))/diff);
          b: 
            if (r >= g)
              hue_f <= (240<<4)+(((60<<4)*(r-g))/diff);
            else
              hue_f <= (240<<4)-(((60<<4)*(g-r))/diff);
        endcase
      end
    end
  end

  initial begin
    $monitor("time: %t, hue: %d", $time, hue, sat, val);
  end

endmodule
