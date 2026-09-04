module apb_slave(
input clk,
input reset,
input psel,
input penable,
input [7:0] paddr,
input [7:0] pwdata,
input pwrite,

output reg pready,
output reg [7:0] prdata
);

reg [7:0] mem[0:255];

integer i;

always @(posedge clk) begin
    if(reset) begin
        for(i=0; i<256; i=i+1)
            mem[i] <= 8'b0;
    end
    else if(psel && penable && pwrite) begin
        mem[paddr] <= pwdata;
    end
end

always @(*) begin
    pready = 1'b0;
    prdata = 8'b0;

    if(psel && penable) begin
        pready = 1'b1;

        if(!pwrite)
            prdata = mem[paddr];
    end
end

endmodule

