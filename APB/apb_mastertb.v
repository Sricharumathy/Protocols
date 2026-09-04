module apb_mastertb();
reg clk,reset,write,transfer;
reg [7:0] addr;
reg [7:0] data_in;
reg pready;
reg [7:0] prdata;
wire psel,penable,pwrite;
wire [7:0] paddr;
wire [7:0] pwdata;
wire [7:0] read_out;


apb_master dut(.clk(clk),.reset(reset),.write(write),.transfer(transfer),.addr(addr),.data_in(data_in),.pready(pready),.prdata(prdata),
 	       .psel(psel),.pwrite(pwrite),.penable(penable),.paddr(paddr),.pwdata(pwdata),.read_out(read_out));

initial begin
clk=0;
forever #10 clk=~clk;
end

initial begin
$dumpfile("apb_master.vcd");
$dumpvars(0,apb_mastertb);
  $monitor("time=%0t state=%0d psel=%b penable=%b pready=%b paddr=%h pwdata=%h",
            $time, dut.state, psel, penable, pready, paddr, pwdata);

//RESET COND
reset=1;
write=0;transfer=0;addr=0;data_in=0;
#20;

reset=0;
pready=1;
addr=8'hA5;
data_in=8'h77;
write=1;
transfer=1;

#40;
transfer=0;
#20;

$finish;
end
endmodule



