module baud_tb();
reg clk;
reg reset;
wire tick_16x;

baud_tick dut(clk,reset,tick_16x);

always #10 clk=~clk;
initial begin
	$dumpfile("baud_tick.vcd");
    $dumpvars(0, baud_tb);
clk=0;
reset=1;
#20;
reset=0;
#20000;
$finish;
end
always @(posedge tick_16x) begin
    $display("tick_16x pulsed at time = %0t", $time);
end
endmodule

