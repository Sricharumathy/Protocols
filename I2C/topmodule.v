module i2c_master_top (
    input        clk_50mhz,
    input        reset,

    input        start,        // pulse high for 1 clk to kick off a transaction
    input        rw,           // 0 = write, 1 = read
    input        more_data,    // write-only: keep bus for another byte (repeated start)

    input  [6:0] slave_addr,
    input  [7:0] pointer_addr, // register/memory pointer inside the slave
    input  [7:0] data_in,      // write-only: byte to send

    output [7:0] data_out,     // read-only: byte received
    output       busy,
    output       done,

    inout        scl,
    inout        sda
);

    // Gate the start pulse to the FSM selected by rw
    wire start_write = start & ~rw;
    wire start_read  = start &  rw;

    wire       busy_w, done_w;
    wire       busy_r, done_r;
    wire [7:0] data_out_r;

    write u_i2c_write (
        .clk_50mhz    (clk_50mhz),
        .reset        (reset),
        .start        (start_write),
        .more_data    (more_data),
        .slave_addr   (slave_addr),
        .pointer_addr (pointer_addr),
        .data_in      (data_in),
        .busy         (busy_w),
        .done         (done_w),
        .scl          (scl),
        .sda          (sda)
    );

    read u_i2c_read (
        .clk_50mhz    (clk_50mhz),
        .reset        (reset),
        .start        (start_read),
        .slave_addr   (slave_addr),
        .pointer_addr (pointer_addr),
        .data_out     (data_out_r),
        .busy         (busy_r),
        .done         (done_r),
        .scl          (scl),
        .sda          (sda)
    );

    // Mux by rw — don't OR these. Write's `done` is sticky (only clears on
    // the next write start), so OR-ing would make a later read look
    // instantly "done" off stale write status.
    assign busy     = rw ? busy_r : busy_w;
    assign done     = rw ? done_r : done_w;
    assign data_out = data_out_r;

endmodule
