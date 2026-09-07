module apb_top(
    input clk,
    input reset,
    input write,
    input transfer,
    input [7:0] addr,
    input [7:0] data_in,
    output [7:0] read_data
);

wire psel,penable,pwrite,pready;
wire [7:0] paddr;
wire [7:0] pwdata;
wire [7:0] prdata;

wire psel0, psel1;
wire pready0,pready1;
wire [7:0] prdata0,prdata1;

apb_master dut(
    .clk(clk), .reset(reset), .write(write), .transfer(transfer),
    .addr(addr), .data_in(data_in),
    .pready(pready), .prdata(prdata),
    .psel(psel), .pwrite(pwrite), .penable(penable),
    .paddr(paddr), .pwdata(pwdata), .read_out(read_data)
);

assign psel0 = psel && (paddr[7]==1'b0);
assign psel1 = psel && (paddr[7]==1'b1);
assign pready = psel0 ? pready0 : (psel1 ? pready1 : 1'b0);
assign prdata = psel0 ? prdata0 : (psel1 ? prdata1 : 8'b0);

apb_slave1 dut1(
    .clk(clk), .reset(reset), .psel(psel0), .penable(penable),
    .paddr(paddr), .pwdata(pwdata), .pwrite(pwrite),
    .pready1(pready0), .prdata1(prdata0)
);

apb_slave2 dut2(
    .clk(clk), .reset(reset), .psel(psel1), .penable(penable),
    .paddr(paddr), .pwdata(pwdata), .pwrite(pwrite),
    .pready2(pready1), .prdata2(prdata1)
);

endmodule
