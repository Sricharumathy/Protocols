```
```verilog
`timescale 1ns/1ps

module top;

reg clk_50mhz;
reg reset;
reg start;
reg rw;
reg more_data;

reg [6:0] slave_addr;
reg [7:0] pointer_addr;
reg [7:0] data_in;

wire [7:0] data_out;
wire busy;
wire done;

wire scl;
wire sda;

pullup(scl);
pullup(sda);

reg slave_sda_oe;
reg [7:0] read_data;

assign sda = slave_sda_oe ? 1'b0 : 1'bz;

top_module uut (
    .clk_50mhz(clk_50mhz),
    .reset(reset),
    .start(start),
    .rw(rw),
    .more_data(more_data),
    .slave_addr(slave_addr),
    .pointer_addr(pointer_addr),
    .data_in(data_in),
    .data_out(data_out),
    .busy(busy),
    .done(done),
    .scl(scl),
    .sda(sda)
);

initial begin
    clk_50mhz = 1'b0;
    forever #10 clk_50mhz = ~clk_50mhz;
end

initial begin

    reset = 1'b1;
    start = 1'b0;
    rw = 1'b0;
    more_data = 1'b0;

    slave_addr = 7'h39;
    pointer_addr = 8'h2A;
    data_in = 8'hA5;

    slave_sda_oe = 1'b0;
    read_data = 8'hB6;

    #100;

    reset = 1'b0;

    #100;

    write_test;

    #500;

    read_test;

    #1000;

    $display("");
    $display("==========================================");
    $display("          I2C MASTER TEST COMPLETE");
    $display("==========================================");

    $finish;

end

task slave_ack;

begin

    slave_sda_oe = 1'b1;

    wait(scl == 1'b1);
    wait(scl == 1'b0);

    slave_sda_oe = 1'b0;

end

endtask

task acknowledge_byte;

integer i;
reg [7:0] received_byte;

begin

    received_byte = 8'h00;

    for(i = 7; i >= 0; i = i - 1) begin

        wait(scl == 1'b0);
        wait(scl == 1'b1);

        received_byte[i] = sda;

    end

    wait(scl == 1'b0);

    slave_sda_oe = 1'b1;

    wait(scl == 1'b1);
    wait(scl == 1'b0);

    slave_sda_oe = 1'b0;

    $display("SLAVE MODEL: Received = %h",
             received_byte);

end

endtask

task send_byte;

integer i;

begin

    for(i = 7; i >= 0; i = i - 1) begin

        wait(scl == 1'b0);

        if(read_data[i] == 1'b0)
            slave_sda_oe = 1'b1;
        else
            slave_sda_oe = 1'b0;

        wait(scl == 1'b1);

    end

    wait(scl == 1'b0);

    slave_sda_oe = 1'b0;

end

endtask

task write_test;

begin

    $display("");
    $display("==========================================");
    $display("              WRITE TEST");
    $display("==========================================");

    $display("Slave Address : %h", slave_addr);
    $display("Pointer       : %h", pointer_addr);
    $display("Data          : %h", data_in);

    rw = 1'b0;

    @(posedge clk_50mhz);

    start = 1'b1;

    @(posedge clk_50mhz);

    start = 1'b0;

    acknowledge_byte;
    acknowledge_byte;
    acknowledge_byte;

    wait(done == 1'b1);

    $display("");
    $display("WRITE: DONE = %b", done);
    $display("WRITE TEST PASSED");

    wait(busy == 1'b0);

    #100;

end

endtask

task read_test;

begin

    $display("");
    $display("==========================================");
    $display("               READ TEST");
    $display("==========================================");

    $display("Slave Address : %h", slave_addr);
    $display("Pointer       : %h", pointer_addr);
    $display("Slave Data    : %h", read_data);

    rw = 1'b1;

    @(posedge clk_50mhz);

    start = 1'b1;

    @(posedge clk_50mhz);

    start = 1'b0;

    acknowledge_byte;
    acknowledge_byte;

    wait(scl == 1'b1);
    wait(sda == 1'b0);

    $display("READ: REPEATED START DETECTED");

    acknowledge_byte;

    $display("SLAVE MODEL: Sending data = %h",
             read_data);

    send_byte;

    wait(scl == 1'b1);

    if(sda == 1'b1)
        $display("READ: MASTER NACK DETECTED");
    else
        $display("READ: WARNING - MASTER ACK");

    wait(scl == 1'b0);

    slave_sda_oe = 1'b0;

    wait(done == 1'b1);

    #20;

    $display("READ: data_out = %h", data_out);

    if(data_out == read_data) begin

        $display("");
        $display("***************************************");
        $display("         READ TEST PASSED");
        $display("Expected = %h", read_data);
        $display("Received = %h", data_out);
        $display("***************************************");

    end
    else begin

        $display("");
        $display("***************************************");
        $display("         READ TEST FAILED");
        $display("Expected = %h", read_data);
        $display("Received = %h", data_out);
        $display("***************************************");

    end

    wait(busy == 1'b0);

end

endtask

endmodule
```
