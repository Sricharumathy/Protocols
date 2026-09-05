module apb_tb();
reg clk,reset,write,transfer;
reg [7:0] addr;
reg [7:0] data_in;
wire pready;
wire [7:0] prdata;
wire psel,penable,pwrite;
wire [7:0] paddr;
wire [7:0] pwdata;
wire [7:0] read_out;

wire psel0,psel1;
wire pready0,pready1;
wire [7:0] prdata0,prdata1;


apb_master dut(.clk(clk),.reset(reset),.write(write),.transfer(transfer),.addr(addr),.data_in(data_in),.pready(pready),.prdata(prdata),
               .psel(psel),.pwrite(pwrite),.penable(penable),.paddr(paddr),.pwdata(pwdata),.read_out(read_out));
apb_slave1 dut1(.clk(clk),.reset(reset),.psel(psel0),.penable(penable),.paddr(paddr),.pwdata(pwdata),.pwrite(pwrite),.pready1(pready0),.prdata1(prdata0));
apb_slave2 dut2 (.clk(clk),.reset(reset),.psel(psel1),.penable(penable),.paddr(paddr),.pwdata(pwdata),.pwrite(pwrite),.pready2(pready1),.prdata2(prdata1));
assign psel0 = psel && (paddr[7]==1'b0);   
assign psel1 = psel && (paddr[7]==1'b1);   
assign pready = psel0 ? pready0 : (psel1 ? pready1 : 1'b0);
assign prdata = psel0 ? prdata0 : (psel1 ? prdata1 : 8'b0);

initial begin
clk=0;
forever #10 clk=~clk;
end

initial begin
$dumpfile("apb.vcd");
$dumpvars(0,apb_tb);
  $monitor("time=%0t state=%0d psel=%b penable=%b pready=%b paddr=%h pwdata=%h",
            $time, dut.state, psel, penable, pready, paddr, pwdata);

//RESET COND
reset=1;
write=0;transfer=0;addr=0;data_in=0;
#20;

reset=0;
//WRITE TEST 
addr=8'hA5;
data_in=8'h77;
write=1;
transfer=1;
#40;
transfer=0;
#20;


// READ BACK TEST
addr=8'hA5;
write=0;
transfer=1;
#40;
transfer=0;
#20;

//WRITE TEST
addr=8'h43;
data_in=8'h21;
write=1;
transfer=1;
#40;
transfer=0;
#20;

//READ BACK TEST
addr=8'h43;
write=0;
transfer=1;
#40;
transfer=0;
#20;



$finish;

end
endmodule


