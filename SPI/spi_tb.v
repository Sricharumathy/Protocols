module spi_tb;

reg clk;
reg rst;
reg start;
reg miso;
reg [3:0] data_in;

wire sclk;
wire cs;
wire mosi;
wire [3:0] data_out;
wire busy;
wire done;

spi dut(
    .clk(clk),
    .rst(rst),
    .start(start),
    .miso(miso),
    .data_in(data_in),
    .sclk(sclk),
    .cs(cs),
    .mosi(mosi),
    .data_out(data_out),
    .busy(busy),
    .done(done)
);

always #5 clk = ~clk;

initial begin
	$dumpfile("spi.vcd");
	$dumpvars(0,spi_tb);
    clk = 0;
    rst = 1;
    start = 0;
    miso = 0;
    data_in = 4'b1010;

    #10;
    rst = 0;

    #10;
    start = 1;

    #10;
    start = 0;

    #20;
    miso = 1;

    #20;
    miso = 0;

    #20;
    miso = 1;

    #20;
    miso = 1;

    #100;
    $finish;
end

initial begin
    $monitor("time=%0t clk=%b rst=%b start=%b cs=%b sclk=%b mosi=%b miso=%b data_out=%b busy=%b done=%b",
             $time,clk,rst,start,cs,sclk,mosi,miso,data_out,busy,done);
end

endmodule
