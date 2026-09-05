module uart_tx #(parameter P_ENB =0)(
input clk,rst,tick_16x,txstart,
input [7:0] data_in,
output reg tx,tx_busy);

localparam IDLE=3'b000,START=3'b001,DATA=3'b010,PARITY=3'b011,STOP=3'b100;

reg [2:0] state,next_state;
reg [3:0] tick_count;
reg [2:0] bit_count;
reg [7:0] shft_reg;
reg parity_bit;

//SEQUENTIAL LOGIC
always @(posedge clk) begin
if(rst) begin
state<=IDLE;
tick_count<=0;
bit_count<=0;
shft_reg<=0;
end
else begin
state<=next_state;
if (state == IDLE)
    tick_count <= 0;
else if (tick_16x && tick_count==15)
    tick_count <= 0;
else if (tick_16x)
    tick_count <= tick_count + 1;
if (state==DATA && tick_16x && tick_count==15)
    bit_count <= bit_count + 1;
else if (state != DATA)
    bit_count <= 0;
if(state==IDLE && txstart) begin
	shft_reg<=data_in;
	parity_bit <= ^data_in;	
end
else if(state==DATA && tick_16x && tick_count==15)
	shft_reg<=shft_reg>>1;
end
end

//COMBINATIONAL LOGIC
always @(*) begin
	next_state=state;
	case(state)
		IDLE: begin
			if(txstart)
				next_state=START;
			else
				next_state=IDLE;
		end
		START: begin
			if(tick_16x && tick_count ==15)
				next_state=DATA;
			else
				next_state=START;
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
//OUTPUT LOGIC
always @(*) begin
    case(state)
        IDLE:   begin tx = 1'b1; tx_busy = 1'b0; end
        START:  begin tx = 1'b0; tx_busy = 1'b1; end
        DATA:   begin tx = shft_reg[0]; tx_busy = 1'b1; end
        PARITY: begin tx = parity_bit; tx_busy = 1'b1; end
        STOP:   begin tx = 1'b1; tx_busy = 1'b1; end
        default: begin tx = 1'b1; tx_busy = 1'b0; end
    endcase
end
endmodule
