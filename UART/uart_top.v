module uart_top #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 9600,
    parameter P_ENB     = 0
)(
    input  clk,
    input  rst,
    input  txstart,
    input  [7:0] data_in,
    output tx_busy,
    output [7:0] data_out,
    output rxdone
);

    wire tick_16x;
    wire tx_line;   // internal wire connecting TX output to RX input

    baud_tick #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) baud_gen (
        .clk(clk),
        .reset(rst),
        .tick_16x(tick_16x)
    );

    uart_tx #(
        .P_ENB(P_ENB)
    ) tx_inst (
        .clk(clk),
        .rst(rst),
        .tick_16x(tick_16x),
        .txstart(txstart),
        .data_in(data_in),
        .tx(tx_line),
        .tx_busy(tx_busy)
    );

    uart_rx #(
        .P_ENB(P_ENB)
    ) rx_inst (
        .clk(clk),
        .rst(rst),
        .tick_16x(tick_16x),
        .rx(tx_line),
        .data_out(data_out),
        .rxdone(rxdone)
    );

endmodule
