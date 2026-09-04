`timescale 1ns/1ps

module apb_tb;

reg        clk;
reg        reset;
reg        write;
reg        transfer;
reg  [7:0] addr;
reg  [7:0] data_in;

wire       pready;
wire [7:0] prdata;

wire       psel;
wire       penable;
wire       pwrite;
wire [7:0] paddr;
wire [7:0] pwdata;

wire [7:0] read_out;

apb_master master (
    .clk       (clk),
    .reset     (reset),
    .write     (write),
    .transfer  (transfer),
    .addr      (addr),
    .data_in   (data_in),
    .pready    (pready),
    .prdata    (prdata),
    .psel      (psel),
    .penable   (penable),
    .pwrite    (pwrite),
    .paddr     (paddr),
    .pwdata    (pwdata),
    .read_out  (read_out)
);

apb_slave slave (
    .clk       (clk),
    .reset     (reset),
    .psel      (psel),
    .penable   (penable),
    .paddr     (paddr),
    .pwdata    (pwdata),
    .pwrite    (pwrite),
    .pready    (pready),
    .prdata    (prdata)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

    reset    = 1;
    write    = 0;
    transfer = 0;
    addr     = 8'h00;
    data_in  = 8'h00;

    #20;
    reset = 0;

    @(posedge clk);

    addr     <= 8'h10;
    data_in  <= 8'hAB;
    write    <= 1'b1;
    transfer <= 1'b1;

    @(posedge clk);

    transfer <= 1'b0;

    wait(pready);

    @(posedge clk);

    addr     <= 8'h10;
    write    <= 1'b0;
    transfer <= 1'b1;

    @(posedge clk);

    transfer <= 1'b0;

    wait(pready);

    @(posedge clk);

    $display("--------------------------------");
    $display("READ TEST");
    $display("Address  = %h", addr);
    $display("Read Data = %h", read_out);
    $display("--------------------------------");

    @(posedge clk);

    addr     <= 8'h20;
    data_in  <= 8'h55;
    write    <= 1'b1;
    transfer <= 1'b1;

    @(posedge clk);

    transfer <= 1'b0;

    wait(pready);

    @(posedge clk);

    addr     <= 8'h20;
    write    <= 1'b0;
    transfer <= 1'b1;

    @(posedge clk);

    transfer <= 1'b0;

    wait(pready);

    @(posedge clk);

    $display("--------------------------------");
    $display("READ TEST");
    $display("Address  = %h", addr);
    $display("Read Data = %h", read_out);
    $display("--------------------------------");

    #20;

    $finish;

end

initial begin
    $dumpfile("apb_wave.vcd");
    $dumpvars(0, apb_tb);
end

endmodule
