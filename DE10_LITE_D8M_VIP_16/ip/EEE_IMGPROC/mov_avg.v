module mov_avg(
  input             clk, rst,
  input      [23:0] x,
  output reg [23:0] x_avg
);

parameter BIT = 3;
parameter LEN = 1<<(BIT-1);

reg  [23:0] list [LEN-1:0];
wire [23:0] temp [LEN-1:0];

integer i;
genvar j;

assign temp[0] = list[0];

generate
  for (j=1; j<LEN; j=j+1) begin : sum_list
    assign temp[j] = list[j-1] + temp[j-1];
  end
endgenerate

always @(posedge clk) begin
  list[0] <= x;
  if (~rst)
    for (i=0; i<LEN; i=i+1) begin : shift_register_reset
      list[i] <= 0;
    end
  else
    for (i=0; i<LEN-1; i=i+1) begin : shift_register
      list[i+1] <= list[i];
    end
end

always @(posedge clk) begin
    x_avg <= rst ? (temp[LEN-1]>>(BIT-1)) : 0;
end

endmodule
