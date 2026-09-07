`timescale 1ns/1ps

module tb_uart_top;

    reg clk = 0;
    reg rst = 1;
    reg txstart = 0;
    reg [7:0] data_in = 8'h00;

    wire tx_busy;
    wire [7:0] data_out;
    wire rxdone;

    uart_top #(
        .CLK_FREQ(50_000_000),
        .BAUD_RATE(9600),
        .P_ENB(0)
    ) dut (
        .clk(clk),
        .rst(rst),
        .txstart(txstart),
        .data_in(data_in),
        .tx_busy(tx_busy),
        .data_out(data_out),
        .rxdone(rxdone)
    );

    always #10 clk = ~clk;   // 50 MHz

    task send_byte(input [7:0] byte_to_send);
        begin
            @(posedge clk);
            data_in  = byte_to_send;
            txstart  = 1;
            @(posedge clk);
            txstart  = 0;
            $display("[%0t] Sent byte: 0x%02h (%b)", $time, byte_to_send, byte_to_send);

            wait(rxdone == 1);
            @(posedge clk);
            if (data_out === byte_to_send)
                $display("[%0t] PASS: Received 0x%02h matches sent byte", $time, data_out);
            else
                $display("[%0t] FAIL: Received 0x%02h, expected 0x%02h", $time, data_out, byte_to_send);

            wait(tx_busy == 0);
            #2000; // small gap before next byte
        end
    endtask

    initial begin
        $dumpfile("uart_top.vcd");
        $dumpvars(0, tb_uart_top);

        rst = 1;
        #100;
        rst = 0;
        #100;

        send_byte(8'hA5);   // 10100101 - mixed bits
        send_byte(8'h00);   // all zeros
        send_byte(8'hFF);   // all ones
        send_byte(8'h3C);   // 00111100

        #5000;
        $display("Simulation complete.");
        $finish;
    end

endmodule
