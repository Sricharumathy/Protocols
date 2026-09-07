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

apb_top top(.clk(clk),.reset(reset),.write(write),.transfer(transfer),
            .addr(addr),.data_in(data_in),.read_data(read_out));
initial begin
clk=0;
forever #10 clk=~clk;
end

initial begin
$dumpfile("apb.vcd");
$dumpvars(0,apb_tb);
  $monitor("time=%0t state=%0d psel=%b penable=%b pready=%b paddr=%h pwdata=%h read_out=%h",
            $time, top.dut.state, top.psel, top.penable, top.pready, top.paddr, top.pwdata, read_out);

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


