module spi(
input clk,rst,start,miso,
input [3:0] data_in,
output reg sclk,cs,mosi,
output reg [3:0] data_out,
output reg busy,done
);
localparam idle=2'b00,load=2'b01,shift=2'b10,finish=2'b11;
reg [1:0] state, next_state;
reg [3:0] bit_cnt;
reg [3:0] tx_reg;
reg [3:0] rx_reg;
always @(posedge clk) begin
if(rst)
state<=idle;
else 
state<=next_state;
end 



always @(*) begin
case(state) 
idle: begin
if(start) 
next_state=load;
else
next_state=idle;
end
load: begin
next_state=shift;
end
shift: begin
if(bit_cnt==0)
next_state=finish;
else
next_state=shift;
end
finish: begin
next_state=idle;
end
endcase
end

always @(posedge clk) begin
	if(rst) begin
		tx_reg<=4'b0;
		rx_reg<=4'b0;
		bit_cnt<=4'b0;
		data_out<=4'b0;
		sclk<=1'b0;
		cs<=1'b1;
		mosi<=1'b0;
		busy<=1'b0;
		done<=1'b0;
	end
	else begin 
		done<=1'b0;
		case(state)
			idle: begin
				cs<=1'b0;
				sclk<=1'b0;
				busy<=1'b1;
			end
			load: begin
                tx_reg  <= data_in;
                rx_reg  <= 4'b0;
                bit_cnt <= 4'd3;
                cs      <= 1'b0;
                busy    <= 1'b1;
                mosi    <= data_in[3];
            end
	    shift: begin
                sclk <= ~sclk;

                if(sclk == 1'b0) begin
                    rx_reg[bit_cnt] <= miso;
                end
                else begin
                    if(bit_cnt != 0) begin
                        bit_cnt <= bit_cnt - 1'b1;
                        mosi <= tx_reg[bit_cnt-1];
                    end
                end
            end

            finish: begin
                cs       <= 1'b1;
                sclk     <= 1'b0;
                busy     <= 1'b0;
                data_out <= rx_reg;
		done     <= 1'b1;
            end
        endcase
    end
end

endmodule




