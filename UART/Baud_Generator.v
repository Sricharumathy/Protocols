module baud_tick #(parameter CLK_FREQ =50_000_000,parameter BAUD_RATE=9600)(
input clk,
input reset,
output reg tick_16x
);

localparam DIVISOR = CLK_FREQ/(BAUD_RATE*16);

reg [$clog2(DIVISOR)-1:0] count;

always @(posedge clk) begin
if(reset) begin
count<=0;
tick_16x<=0;
end
else if(count==DIVISOR-1) begin
count<=0;
tick_16x<=1;
end
else begin
count<=count+1;
tick_16x<=0;
end
end
endmodule
