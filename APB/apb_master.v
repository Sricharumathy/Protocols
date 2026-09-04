module apb_master(
input clk,
input reset,
input write,
input transfer,
input [7:0] addr,
input [7:0] data_in,

input pready,
input [7:0] prdata,


output reg psel,penable,pwrite,
output reg [7:0] paddr,
output reg [7:0] pwdata,
output reg [7:0] read_out
);

localparam IDLE =2'b00,SETUP=2'b01,ACCESS=2'b10;

reg [1:0] state,nextstate;

// STATE LOGIC
always @(posedge clk) begin
if(reset)  begin
state<=IDLE;
read_out<=8'b0;
end

else begin
state<=nextstate;
if(state==ACCESS && pready && !pwrite)
	read_out<=prdata;
end
end

//NEXTSTATE LOGIC
always @(*) begin
case(state)
IDLE: begin
if(transfer) 
nextstate=SETUP;
else
nextstate=IDLE;
end
SETUP: begin
nextstate=ACCESS;
end
ACCESS: begin
if(pready) begin
if(transfer)
nextstate=SETUP;
else
nextstate=IDLE;
end
else 
nextstate=ACCESS;
end
default:
	nextstate=IDLE;
endcase
end

//OUTPUT LOGIC
always @(*) begin
    psel    = 0;
    penable = 0;
    pwrite  = 0;
    paddr   = 0;
    pwdata  = 0;

    case(state)
        IDLE: begin
            psel = 0;
            penable = 0;
        end

        SETUP: begin
            psel = 1;
            penable = 0;
            pwrite = write;
            paddr = addr;
            pwdata = data_in;
        end

        ACCESS: begin
            psel = 1;
            penable = 1;
            pwrite = write;
            paddr = addr;
            pwdata = data_in;
        end
	default: begin
		psel=0;
		penable=0;
	end

    endcase
end
endmodule









