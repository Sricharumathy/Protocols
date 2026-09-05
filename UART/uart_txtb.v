`timescale 1ns/1ps

module uart_tb;

reg clk;
reg rst;
reg txstart;
reg [7:0] data_in;

wire tx;
wire tx_busy;
wire tick_16x;

baud_tick #(
    .CLK_FREQ(50_000_000),
    .BAUD_RATE(9600)
) baud_gen (
    .clk(clk),
    .reset(rst),
    .tick_16x(tick_16x)
);

uart_tx #(
    .P_ENB(1)
) uart (
    .clk(clk),
    .rst(rst),
    .tick_16x(tick_16x),
    .txstart(txstart),
    .data_in(data_in),
    .tx(tx),
    .tx_busy(tx_busy)
);

always #10 clk = ~clk;

initial begin
    clk = 0;
    rst = 1;
    txstart = 0;
    data_in = 8'h00;

    #100;
    rst = 0;

    #100;
    data_in = 8'h41;
    txstart = 1;

    #20;
    txstart = 0;

    wait(tx_busy);
    wait(!tx_busy);

    #100;

    data_in = 8'h55;
    txstart = 1;

    #20;
    txstart = 0;

    wait(tx_busy);
    wait(!tx_busy);

    #100;
    $finish;
end

initial begin
    $monitor("time=%0t rst=%b txstart=%b data=%h tick=%b tx=%b busy=%b state=%b",
             $time, rst, txstart, data_in, tick_16x, tx, tx_busy, uart.state);
end

initial begin
    $dumpfile("uart.vcd");
    $dumpvars(0, uart_tb);
end

endmodule
