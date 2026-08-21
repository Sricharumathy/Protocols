module i2c_wr
(
input clk,rst,start,has_pntr,
input [6:0] slv_addr,
input [7:0] pntr_addr,
input [7:0] data_in,
input more_data,
output reg busy,
output reg done,
output reg ack_error,
inout sda,
inout scl
);

//state declaration
parameter IDLE =4'd0,
	START =4'd1,
	SLV_ADDR=4'd2,
	SLV_ACK=4'd3,
	PNTR_ADDR=4'd4,
	PNTR_ACK=4'd5,
	DATA_WR=4'd6,
	DATA_ACK=4'd7,
	STOP=4'd8,
	DONE=4'd9;

reg [3:0] state,next_state;
reg [6:0] clk_count;
reg i2c_tick;
reg [1:0] scl_phase;
reg [2:0] bit_count;
reg [7:0] tx_shift;
reg [7:0] pntr_shift;
reg [7:0] data_shift;




//Clock Calculation 50Mhz--->400Khz
always @(posedge clk) begin
	if(rst) begin
		clk_count<=7'b0;
		i2c_tick<=1'b0;
	end
	else if(clk_count==7'd124) begin
		clk_count<=7'b0;
		i2c_tick<=1'b1;
	end
	else begin
		clk_count<=clk_count+7'd1;
		i2c_tick<=1'b0;
	end
end
//400khz---->100 khz(4 phases)
always @(posedge clk) begin
	if(rst)
		scl_phase<=2'b00;
	else if(i2c_tick)
		scl_phase<=scl_phase+2'b01;
end
// End of one Complete SCL bit time
wire i2c_step;
assign i2c_step=i2c_tick &&(scl_phase==2'd3);

//Open Drain Control
reg scl_drive_low;
reg sda_drive_low;
//drive_low or Release
assign scl = (scl_drive_low==1)? 1'b0:1'bz;
assign sda = (sda_drive_low==1)? 1'b0:1'bz;
//Read the actual bus value
wire scl_in=scl;
wire sda_in=sda;


// STATE LOGIC SEQUENTIAL
always @(posedge clk) begin
	if(rst)
		state<=IDLE;
	else
		state<=next_state;
end

//NEXT STATE LOGIC COMBINATIONAL
always @(*) begin
	next_state=state;
	case(state)
		IDLE: begin
			if(start)
				next_state=START;
			else
				next_state=IDLE;
		end
		START: begin
			if(i2c_step)
				next_state=SLV_ADDR;
		end
		SLV_ADDR: begin
			if(i2c_step && (bit_count==3'b111))
				next_state=SLV_ACK;
		end
		SLV_ACK: begin
			if(i2c_step) begin
				if(sda_in==1'b0)begin
					if(has_pntr)
						next_state=PNTR_ADDR;
					else
						next_state=DATA_WR;
				end
				else 
					next_state=STOP;
			end
		end
		PNTR_ADDR: begin
			if(i2c_step && (bit_count==3'b111))
				next_state=PNTR_ACK;
		end
		PNTR_ACK: begin
			if(i2c_step) begin
				if(sda_in==1'b0)
					next_state=DATA_WR;
				else
					next_state=STOP;
			end
		end
		DATA_WR: begin
			if(i2c_step && (bit_count==3'b111))
				next_state=DATA_ACK;
		end
		DATA_ACK: begin
			if(i2c_step) begin
				if(sda_in==1'b0) begin
					if(more_data) begin
						if(has_pntr)
							next_state=PNTR_ADDR;
						else
							next_state=DATA_WR;
					end
					else begin
						next_state=STOP;
					end
				end
				else begin
					next_state=STOP;
				end

			end
		end
		STOP: begin
			if(i2c_step)
				next_state=DONE;
		end
		DONE: begin
			next_state=IDLE;
		end
		default:begin
			next_state=IDLE;
		end
	endcase
end
// OUTPUT LOGIC
always @(*) begin
	scl_drive_low=1'b0;
	sda_drive_low=1'b0;
	case(state)
		IDLE : begin
			scl_drive_low=1'b0;
			sda_drive_low=1'b0;
		end
		START : begin
			scl_drive_low=1'b0;
			sda_drive_low=1'b1;
		end
		SLV_ADDR: begin
			if((scl_phase==2'd0)||(scl_phase==2'd1))
				scl_drive_low=1'b1;
			else
				scl_drive_low=1'b0;
			//send address bit
			if(tx_shift[7]==1'b0)
				sda_drive_low=1'b1;
			else
				sda_drive_low=1'b0;
		end
		SLV_ACK: begin
			  if ((scl_phase == 2'd0) || (scl_phase == 2'd1))
				  scl_drive_low = 1'b1;
			  else 
				  scl_drive_low = 1'b0;

			  sda_drive_low=1'b0; //Master releases SDA --> then slave is free to control SDA
		  end
		  PNTR_ADDR: begin
			  if((scl_phase==2'd0)||(scl_phase==2'd1))
				  scl_drive_low=1'b1;
			  else
				  scl_drive_low=1'b0;

			  if(pntr_shift[7]==1'b0)
				  sda_drive_low=1'b1;
			  else
				  sda_drive_low=1'b0;
	  	  end
		  PNTR_ACK: begin
			  if((scl_phase==2'd0)||(scl_phase==2'd1))
				  scl_drive_low=1'b1;
			  else
				  scl_drive_low=1'b0;

			  sda_drive_low=1'b0;
		  end
		  DATA_WR: begin
			  if((scl_phase==2'd0)||(scl_phase==2'd1))
                                  scl_drive_low=1'b1;
                          else
                                  scl_drive_low=1'b0;
                          if(data_shift[7]==1'b0)
                                  sda_drive_low=1'b1;
                          else
				  sda_drive_low=1'b0;
		  end
		  DATA_ACK: begin
			   if((scl_phase==2'd0)||(scl_phase==2'd1))
                                  scl_drive_low=1'b1;
                          else
                                  scl_drive_low=1'b0;

                          sda_drive_low=1'b0;
		  end
		  DONE: begin
			  scl_drive_low=1'b0;
			  sda_drive_low=1'b0;
		  end
		  STOP: begin
			  if((scl_phase==2'd0)||(scl_phase==2'd1)) begin
				  scl_drive_low=1'b1;
              			  sda_drive_low=1'b1;
			  end
			  else if (scl_phase==2'd2) begin
				  scl_drive_low=1'b0;
				  sda_drive_low=1'b1;
			  end
			  else begin
				  scl_drive_low=1'b0;
				  sda_drive_low=1'b0;
			  end

		  end
		  default:begin
			  scl_drive_low=1'b0;
			  sda_drive_low=1'b0;
		  end
	  endcase
  end
//SEQUENTIAL LOGIC
always @(posedge clk) begin
	if(rst) begin
		bit_count<=3'd0;
		tx_shift<=8'd0;
		pntr_shift<=8'd0;
		data_shift<=8'd0;
	end
	else begin
		case(state)
			START: begin
				if(i2c_step) begin
					tx_shift<={slv_addr,1'b0};
					bit_count<=3'd0;
				end
			end
			SLV_ADDR: begin
				if(i2c_step) begin
					if(bit_count==3'd7) begin
						bit_count<=3'd0;
					end
					else begin
						bit_count<=bit_count+3'd1;
					end

					tx_shift<={tx_shift[6:0],1'b0};
				end
			end
			SLV_ACK: begin
				if(i2c_step) begin
					bit_count<=3'd0;
					if(has_pntr)
						pntr_shift<=pntr_addr;
					else
						data_shift<=data_in;
				end
			end

			PNTR_ADDR: begin
				 if(i2c_step) begin
                                        if(bit_count==3'd7) begin
                                                bit_count<=3'd0;
                                        end
                                        else begin
                                                bit_count<=bit_count+3'd1;
                                        end

                                        pntr_shift<={pntr_shift[6:0],1'b0};
                                end
                        end
			PNTR_ACK: begin
				if(i2c_step) begin
					bit_count<=3'd0;
					data_shift<=data_in;
				end
			end

			DATA_WR: begin
				 if(i2c_step) begin
                                        if(bit_count==3'd7) begin
                                                bit_count<=3'd0;
                                        end
                                        else begin
                                                bit_count<=bit_count+3'd1;
                                        end

                                        data_shift<={data_shift[6:0],1'b0};
                                end
                        end
			DATA_ACK: begin
				if(i2c_step) begin
					bit_count<=3'd0;
					if(more_data)
						data_shift<=data_in;
				end
			end

		endcase
	end 
end
// OUTPUT / STATUS LOGIC
always @(posedge clk) begin

    if (rst) begin
        busy      <= 1'b0;
        done      <= 1'b0;
	ack_error <= 1'b0;
    end

    else begin

            done <= 1'b0;

        case (state)

            IDLE: begin
                busy <= 1'b0;

                if (start)
                    ack_error <= 1'b0;
            end

            START: begin
                busy <= 1'b1;
            end

            SLV_ADDR: begin
                busy <= 1'b1;
            end

            SLV_ACK: begin
                busy <= 1'b1;

                // Slave did not acknowledge
                if (i2c_step && (sda_in == 1'b1))
                    ack_error <= 1'b1;
            end

            PNTR_ADDR: begin
                busy <= 1'b1;
            end

            PNTR_ACK: begin
                busy <= 1'b1;

                // Pointer address was not acknowledged
                if (i2c_step && (sda_in == 1'b1))
                    ack_error <= 1'b1;
            end

            DATA_WR: begin
                busy <= 1'b1;
            end

            DATA_ACK: begin
                busy <= 1'b1;

                // Data was not acknowledged
                if (i2c_step && (sda_in == 1'b1))
                    ack_error <= 1'b1;
            end

            STOP: begin
                busy <= 1'b1;
            end

            DONE: begin
                busy <= 1'b0;
                done <= 1'b1;
            end

            default: begin
                busy <= 1'b0;
            end

        endcase
    end
end

endmodule








 


























