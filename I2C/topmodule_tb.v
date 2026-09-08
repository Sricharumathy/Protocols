`timescale 1ns/1ps

module i2c_master_top_tb;

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

    // ---- fake slave behaviour ----
    reg slave_drive_low;   // drives sda low to ACK, or to send read data bits
    reg [7:0] slave_read_data;

    i2c_master_top dut (
        .clk_50mhz    (clk_50mhz),
        .reset        (reset),
        .start        (start),
        .rw           (rw),
        .more_data    (more_data),
        .slave_addr   (slave_addr),
        .pointer_addr (pointer_addr),
        .data_in      (data_in),
        .data_out     (data_out),
        .busy         (busy),
        .done         (done),
        .scl          (scl),
        .sda          (sda)
    );

    pullup(scl);
    pullup(sda);

    assign sda = slave_drive_low ? 1'b0 : 1'bz;

    // 50 MHz clock
    initial begin
        clk_50mhz = 1'b0;
        forever #10 clk_50mhz = ~clk_50mhz;
    end

    // ACK generation for both write-FSM and read-FSM ack/data states
    always @(*) begin
        slave_drive_low = 1'b0;

        if (rw == 1'b0) begin
            // WRITE transaction: ACK slave addr / pointer / data bytes
            case (dut.u_i2c_write.state)
                dut.u_i2c_write.SLAVE_ACK:   slave_drive_low = 1'b1;
                dut.u_i2c_write.POINTER_ACK: slave_drive_low = 1'b1;
                dut.u_i2c_write.DATA_ACK:    slave_drive_low = 1'b1;
                default:                     slave_drive_low = 1'b0;
            endcase
        end
        else begin
            // READ transaction: ACK addr phases + drive read data bits
            case (dut.u_i2c_read.state)
                dut.u_i2c_read.SLAVE_ACK_W:   slave_drive_low = 1'b1;
                dut.u_i2c_read.POINTER_ACK:   slave_drive_low = 1'b1;
                dut.u_i2c_read.SLAVE_ACK_R:   slave_drive_low = 1'b1;
                dut.u_i2c_read.READ_DATA:     slave_drive_low = ~slave_read_data[dut.u_i2c_read.bit_count];
                default:                      slave_drive_low = 1'b0;
            endcase
        end
    end

    initial begin
        reset        = 1'b1;
        start        = 1'b0;
        rw           = 1'b0;
        more_data    = 1'b0;
        slave_addr   = 7'h57;
        pointer_addr = 8'h2A;
        data_in      = 8'hA5;
        slave_read_data = 8'h3C;

        #100;
        reset = 1'b0;
        #100;

        // ---------------- WRITE TRANSACTION ----------------
        rw    = 1'b0;
        start = 1'b1;
        wait (busy == 1'b1);
        start = 1'b0;
        wait (done == 1'b1);
        #100;

        $display("-----------------------------------------");
        $display("I2C TOP: WRITE TRANSACTION COMPLETED");
        $display("-----------------------------------------");

        wait (busy == 1'b0);
        #200;

        // ---------------- READ TRANSACTION ----------------
        rw           = 1'b1;
        pointer_addr = 8'h2A;
        start        = 1'b1;
        wait (busy == 1'b1);
        start = 1'b0;
        wait (done == 1'b1);
        #100;

        $display("-----------------------------------------");
        $display("I2C TOP: READ TRANSACTION COMPLETED, data_out = 0x%0h", data_out);
        $display("-----------------------------------------");

        #200;
        $finish;
    end

    initial begin
        $monitor(
            "TIME=%0t | RW=%b | START=%b | BUSY=%b | DONE=%b | SCL=%b | SDA=%b | DATA_OUT=0x%0h",
            $time, rw, start, busy, done, scl, sda, data_out
        );
    end

    initial begin
        $dumpfile("i2c_master_top.vcd");
        $dumpvars;
    end

endmodule

