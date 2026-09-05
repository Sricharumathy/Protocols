module apb_slave1(
input clk,
input reset,
input psel,
input penable,
input [7:0] paddr,
input [7:0] pwdata,
input pwrite,

output reg pready1,
output reg [7:0] prdata1
);

reg [7:0] mem[0:255];

integer i;
initial begin
	for(i=0;i<256;i=i+1)
		mem[i]=8'b0;
end
always @(posedge clk) begin
	if(reset) begin
		for(i=0;i<256;i=i+1)
			mem[i]<=8'b0;
	end
	else if(psel && penable && pwrite && pready1)
		mem[paddr]<=pwdata;
end

always @(*) begin
    pready1 = 1'b0;
    prdata1 = 8'b0;

    if(psel && penable) begin
        pready1 = 1'b1;

        if(!pwrite)
            prdata1 = mem[paddr];
    end
end


endmodule

