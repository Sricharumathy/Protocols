module i2c_write_tb;

reg clk_50mhz;
reg reset;
reg start;
reg more_data;

reg [6:0] slave_addr;
reg [7:0] pointer_addr;
reg [7:0] data_in;

wire busy;
wire done;

wire scl;
wire sda;

reg slave_ack;

write uut (
    .clk_50mhz(clk_50mhz),
    .reset(reset),
    .start(start),
    .more_data(more_data),
    .slave_addr(slave_addr),
    .pointer_addr(pointer_addr),
    .data_in(data_in),
    .busy(busy),
    .done(done),
    .scl(scl),
    .sda(sda)
);

pullup(scl);
pullup(sda);

assign sda = slave_ack ? 1'b0 : 1'bz;

initial begin
    clk_50mhz = 1'b0;
    forever #10 clk_50mhz = ~clk_50mhz;
end

initial begin
    reset = 1'b1;
    start = 1'b0;
    more_data=1'b0;
    slave_addr = 7'h57;
    pointer_addr = 8'h2A;
    data_in = 8'hA5;

    #100;

    reset = 1'b0;

    #100;

    start = 1'b1;
    wait(busy==1'b1);
    start=1'b0;
    wait(done == 1'b1);

    #100;

    $display("-----------------------------------------");
    $display("I2C WRITE TRANSACTION COMPLETED");
    $display("-----------------------------------------");

    $finish;
end

always @(*) begin
    case (uut.state)

        uut.SLAVE_ACK:
            slave_ack = 1'b1;

        uut.POINTER_ACK:
            slave_ack = 1'b1;

        uut.DATA_ACK:
            slave_ack = 1'b1;

        default:
            slave_ack = 1'b0;

    endcase
end

initial begin
    $monitor(
        "TIME=%0t | TICK=%b | START=%b |STATE=%0d |NEXT=%0d | SCL=%b | SDA=%b | BIT=%0d |MORE_DATA=%b | BUSY=%b | DONE=%b",
        $time,
	uut.timing_tick,
	start,
        uut.state,
	uut.next_state,
        scl,
        sda,
        uut.bit_count,
	more_data,
        busy,
        done
    );
end

initial begin
    $dumpfile("i2c.vcd");
    $dumpvars;
end

endmodule
