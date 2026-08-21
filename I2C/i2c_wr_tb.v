`timescale 1ns/1ps

module i2c_wr_tb;

reg clk;
reg rst;
reg start;
reg has_pntr;

reg [6:0] slv_addr;
reg [7:0] pntr_addr;
reg [7:0] data_in;
reg more_data;

wire busy;
wire done;
wire ack_error;

tri scl;
tri sda;

reg slave_ack;


//====================================================
// DUT
//====================================================

i2c_wr dut (
    .clk        (clk),
    .rst        (rst),
    .start      (start),
    .has_pntr   (has_pntr),

    .slv_addr   (slv_addr),
    .pntr_addr  (pntr_addr),
    .data_in    (data_in),
    .more_data  (more_data),

    .busy       (busy),
    .done       (done),
    .ack_error  (ack_error),

    .sda        (sda),
    .scl        (scl)
);


//====================================================
// I2C PULL-UP
//====================================================

pullup(scl);
pullup(sda);


//====================================================
// SLAVE ACK
//====================================================
//
// slave_ack = 1 -> slave pulls SDA LOW
// slave_ack = 0 -> slave releases SDA
//

assign sda = slave_ack ? 1'b0 : 1'bz;


//====================================================
// 50 MHz CLOCK
//====================================================

initial begin

    clk = 1'b0;

    forever #10 clk = ~clk;

end


//====================================================
// TEST SEQUENCE
//====================================================

initial begin

    // Initial values
    rst       = 1'b1;
    start     = 1'b0;

    has_pntr  = 1'b1;

    slv_addr  = 7'h50;
    pntr_addr = 8'h20;
    data_in   = 8'hA5;

    more_data = 1'b0;


    // Reset
    #100;

    rst = 1'b0;


    // Wait after reset
    #100;


    // Start I2C write
    start = 1'b1;

    #20;

    start = 1'b0;


    // Wait until transaction completes
    wait(done == 1'b1);


    #200;


    $display("----------------------------------------");
    $display("I2C WRITE TRANSACTION COMPLETED");
    $display("----------------------------------------");
    $display("ACK ERROR = %b", ack_error);


    $finish;

end


//====================================================
// SLAVE ACK GENERATION
//====================================================
//
// Your state values:
//
// IDLE      = 4'd0
// START     = 4'd1
// SLV_ADDR  = 4'd2
// SLV_ACK   = 4'd3
// PNTR_ADDR = 4'd4
// PNTR_ACK  = 4'd5
// DATA_WR   = 4'd6
// DATA_ACK  = 4'd7
// STOP      = 4'd8
// DONE      = 4'd9
//
// Therefore:
//
// state = 3 -> SLV_ACK
// state = 5 -> PNTR_ACK
// state = 7 -> DATA_ACK
//

always @(*) begin

    slave_ack = 1'b0;

    case (dut.state)

        4'd3: begin
            // SLV_ACK
            slave_ack = 1'b1;
        end

        4'd5: begin
            // PNTR_ACK
            slave_ack = 1'b1;
        end

        4'd7: begin
            // DATA_ACK
            slave_ack = 1'b1;
        end

        default: begin
            slave_ack = 1'b0;
        end

    endcase

end


//====================================================
// MONITOR
//====================================================

initial begin

    $monitor(
        "TIME=%0t | STATE=%0d | SCL=%b | SDA=%b | BIT=%0d | BUSY=%b | DONE=%b | ACK_ERR=%b",
        $time,
        dut.state,
        scl,
        sda,
        dut.bit_count,
        busy,
        done,
        ack_error
    );

end


//====================================================
// VCD WAVEFORM
//====================================================

initial begin

    $dumpfile("i2c_write.vcd");

    $dumpvars(0, i2c_wr_tb);

end

endmodule
