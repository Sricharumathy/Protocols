module uart_rx #(parameter P_ENB=0)(
input clk,rst,tick_16x,rx,
output reg [7:0] data_out,
output reg rxdone);

localparam IDLE=3'b000,START=3'b001,DATA=3'b010,PARITY=3'b011,STOP=3'b100;

reg [2:0] state,next_state;
reg [3:0] tick_count;
reg [2:0] bit_count;
reg [7:0] shft_reg;
reg rx_prev;
reg parity_bit;

//SEQUENTIAL LOGIC
always @(posedge clk) begin
if(rst) begin
state<=IDLE;
data_out<=8'b0;
rxdone<=0;
rx_prev<=0;
end
else begin
	rx_prev<=rx;
state<=next_state;
if (state == IDLE)
    tick_count <= 0;
else if (state == START && tick_16x && tick_count==7)
    tick_count <= 0;             
else if (tick_16x && tick_count==15)
    tick_count <= 0;
else if (tick_16x)
    tick_count <= tick_count + 1;
if (state==DATA && tick_16x && tick_count==15)
    bit_count <= bit_count + 1;
else if (state != DATA)
    bit_count <= 0;
if (state==DATA && tick_16x && tick_count==15)
    shft_reg <= {rx, shft_reg[7:1]};
if (state==DATA && tick_16x && tick_count==15 && bit_count==3'd7)
    parity_bit <= ^{rx, shft_reg[7:1]};
if (state==STOP && tick_16x && tick_count==15) begin
    data_out <= shft_reg;
    rxdone   <= 1'b1;
end
else
    rxdone <= 1'b0;
end
end

//COMBINATIONAL LOGIC
always @(*) begin
	next_state=state;
	case(state)
		IDLE : begin
			if(rx_prev==1 && rx==0)
				next_state=START;
			else
				next_state=IDLE;
		end
		START: begin
		       	if (tick_16x && tick_count==7)
				next_state = DATA;
		    	else
			      	next_state = START;
		end
		DATA: begin
			if (tick_16x && tick_count==15) begin
				if (bit_count == 3'd7)
					next_state = P_ENB ? PARITY : STOP;
				else
					next_state = DATA;
			end
			else
				next_state = DATA;
		end
		PARITY: begin
			if(tick_16x && tick_count ==15)
				next_state=STOP;
			else
				next_state=PARITY;
		end
		STOP: begin
			if(tick_16x && tick_count ==15)
				next_state=IDLE;
			else
				next_state=STOP;
		end
		default:
			next_state=IDLE;
	endcase
end

endmodule


