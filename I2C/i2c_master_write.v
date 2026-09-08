module write (
    input clk_50mhz,
    input reset,
    input start,more_data,
    input [6:0] slave_addr,
    input [7:0] pointer_addr,
    input [7:0] data_in,
    output reg busy,
    output reg done,
    inout scl,
    inout sda
);

    reg [7:0] clk_count;
    reg timing_tick;
    reg sda_oe;
    reg scl_oe;
    reg [7:0] data_reg;
    reg [7:0] pointer_reg;
    reg [7:0] addr_reg;
    reg [3:0] bit_count;
    reg scl_phase;
    reg has_pointer;


    parameter IDLE = 4'd0;
    parameter START = 4'd1;
    parameter SLAVE_ADDR= 4'd2;
    parameter SLAVE_ACK = 4'd3;
    parameter POINTER_ADDR= 4'd4;
    parameter POINTER_ACK = 4'd5;
    parameter DATA = 4'd6;
    parameter DATA_ACK = 4'd7;
    parameter REPEATED_START=4'd8;
    parameter STOP = 4'd9;

    reg [3:0] state;
    reg [3:0] next_state;

    always @(posedge clk_50mhz or posedge reset)
    begin
        if (reset) begin
            clk_count <= 8'd0;
            timing_tick <= 1'b0;
        end
        else begin
            timing_tick <= 1'b0;

            if (clk_count == 8'd249) begin
                clk_count <= 8'd0;
                timing_tick <= 1'b1;
            end
            else begin
                clk_count <= clk_count + 1'b1;
            end
        end
    end

    assign scl = scl_oe ? 1'b0 : 1'bz;
    assign sda = sda_oe ? 1'b0 : 1'bz;

    always @(posedge clk_50mhz or posedge reset)
    begin
        if (reset) begin
            state <= IDLE;
            addr_reg <= 7'd0;
            pointer_reg <= 8'd0;
            data_reg <= 8'd0;
            bit_count <= 4'd7;
	    scl_phase <= 1'b0;
            busy <= 1'b0;
            done <= 1'b0;
        end
        else begin
            if (timing_tick) begin

                state <= next_state;
		case(state)
                 IDLE: begin
		  scl_phase<=1'b0;
		  if(start) begin
                    addr_reg <= {slave_addr,1'b0};
                    pointer_reg <= pointer_addr;
                    data_reg <= data_in;
                    bit_count <= 4'd7;
                    busy <= 1'b1;
                    done <= 1'b0;
		end
                end
		START:begin	
			scl_phase<=1'b0;
			bit_count<=4'd7;
		end

                SLAVE_ADDR: begin
		  if(scl_phase==1'b0)begin
			scl_phase<=1'b1;
		  end
		else begin
		    scl_phase<=1'b0;
                    if (bit_count != 0)
                        bit_count <= bit_count - 1'b1;
                    else
                        bit_count <= 4'd7;
                end
		end
		
		SLAVE_ACK:begin
		  if(scl_phase==1'b0)begin
			scl_phase<=1'b1;
		  end
		else begin
		    scl_phase<=1'b0;
		end
		end

                POINTER_ADDR: begin
                    if (scl_phase == 1'b0)
                    begin
                        scl_phase <= 1'b1;
                    end

                    else
                    begin
                        scl_phase <= 1'b0;

                        if (bit_count != 0)
                            bit_count <= bit_count - 1'b1;
                        else
                            bit_count <= 4'd7;
                    end
                end

		POINTER_ACK:
                begin
                    if (scl_phase == 1'b0)
                    begin
                        scl_phase <= 1'b1;
                    end
                    else
                    begin
                        scl_phase <= 1'b0;
                    end
                end

                 DATA:
                begin
                    if (scl_phase == 1'b0)
                    begin
                        scl_phase <= 1'b1;
                    end

                    else
                    begin
                        scl_phase <= 1'b0;

                        if (bit_count != 0)
                            bit_count <= bit_count - 1'b1;
                        else
                            bit_count <= 4'd7;
                    end
                end
		      DATA_ACK:
                begin
                    if (scl_phase == 1'b0)
                    begin
                        scl_phase <= 1'b1;
                    end
                    else
                    begin
                        scl_phase <= 1'b0;
			if(more_data)begin
				data_reg <= data_in;
         		        bit_count <= 4'd7;
				pointer_reg<=pointer_addr;
                         end

                    end
                end
		REPEATED_START:begin
                    if (scl_phase == 1'b0)
                        scl_phase <= 1'b1;
                    
			else begin
       			 scl_phase <= 1'b0;
			bit_count<=4'd7;
			end
		end

                  STOP:
                begin
                    if (scl_phase == 1'b0)
                    begin
                        
                        scl_phase <= 1'b1;
                    end

                    else
                    begin
                       
                        scl_phase <= 1'b0;

                        busy <= 1'b0;
                        done <= 1'b1;
                    end
                end
		 default:
                begin
                    scl_phase <= 1'b0;
                    busy      <= 1'b0;
                    done      <= 1'b0;
                end

            endcase
        end
	end
    end

    always @(*)
    begin
        next_state = state;

        case (state)

            IDLE:
            begin
                if (start)
                    next_state = START;
                else
                    next_state = IDLE;
            end

            START:
            begin
                next_state = SLAVE_ADDR;
            end

            SLAVE_ADDR:
            begin
		if((scl_phase==1'b1)&&(bit_count==4'd0)) begin
			next_state=SLAVE_ACK;
		end
		else begin
                next_state = SLAVE_ADDR;
		end
            end

            SLAVE_ACK:
            begin
		if(scl_phase==1'b1)begin
		if(sda==1'b0)
			next_state=POINTER_ADDR;
		else
                       next_state = STOP;
		end
		else begin
			next_state=SLAVE_ACK;
            		end
	    end
	POINTER_ADDR:begin
                 if ((scl_phase == 1'b1) &&(bit_count == 4'd0))
                begin
                    next_state = POINTER_ACK;
                end
                else
                begin
                    next_state = POINTER_ADDR;
                end
            end


          POINTER_ACK:
            begin
                if (scl_phase == 1'b1)
                begin
                    if (sda == 1'b0)
                        next_state = DATA;
                    else
                        next_state = STOP;
                end
                else
                begin
                    next_state = POINTER_ACK;
                end
            end

            DATA:
            begin
                if ((scl_phase == 1'b1) &&(bit_count == 4'd0))
                begin
                    next_state = DATA_ACK;
                end
                else
                begin
                    next_state = DATA;
                end
            end

            DATA_ACK:begin
                if (scl_phase == 1'b1) begin
			if(more_data)
                    		next_state = REPEATED_START;
			else
				next_state=STOP;
		end
                else
                    next_state = DATA_ACK;
            end
	   REPEATED_START:begin
  		  if (scl_phase == 1'b1)
        		next_state = SLAVE_ADDR;
    		  else
        		next_state = REPEATED_START;
	   end

            STOP:
            begin
                if (scl_phase == 1'b1)
                    next_state = IDLE;
                else
                    next_state = STOP;
            end


            default:
            begin
                next_state = IDLE;
            end

        endcase
    end

    always @(*)
    begin
        scl_oe = 1'b0;
        sda_oe = 1'b0;

        case (state)

            IDLE:
            begin
                scl_oe = 1'b0;
                sda_oe = 1'b0;
            end

            START:
            begin
                scl_oe = 1'b0;
                sda_oe = 1'b1;
            end

            SLAVE_ADDR:
          begin
                if (scl_phase == 1'b0)
                    scl_oe = 1'b1;   
                else
                    scl_oe = 1'b0;   

    
                if (addr_reg[bit_count] == 1'b0)
                    sda_oe = 1'b1;   
                else
                    sda_oe = 1'b0;  

            end

     
            SLAVE_ACK:
              begin

                if (scl_phase == 1'b0)
                    scl_oe = 1'b1;
                else
                    scl_oe = 1'b0;

                // Release SDA
                sda_oe = 1'b0;

            end

            POINTER_ADDR:
            begin

                if (scl_phase == 1'b0)
                    scl_oe = 1'b1;
                else
                    scl_oe = 1'b0;

                if (pointer_reg[bit_count] == 1'b0)
                    sda_oe = 1'b1;
                else
                    sda_oe = 1'b0;

            end

            POINTER_ACK:
             begin

                if (scl_phase == 1'b0)
                    scl_oe = 1'b1;
                else
                    scl_oe = 1'b0;

                // Release SDA
                sda_oe = 1'b0;

            end

            DATA:
            begin

                if (scl_phase == 1'b0)
                    scl_oe = 1'b1;
                else
                    scl_oe = 1'b0;

                if (data_reg[bit_count] == 1'b0)
                    sda_oe = 1'b1;
                else
                    sda_oe = 1'b0;

            end

            DATA_ACK:
             begin

                if (scl_phase == 1'b0)
                    scl_oe = 1'b1;
                else
                    scl_oe = 1'b0;

                // Release SDA
                sda_oe = 1'b0;

            end
	REPEATED_START:
           begin
    	 if (scl_phase == 1'b0)
   	 begin
        	scl_oe = 1'b1;   // SCL LOW
        	sda_oe = 1'b0;   // SDA released
    	end
    	else
    	begin
        	scl_oe = 1'b0;   // SCL HIGH
       	        sda_oe = 1'b1;   // SDA LOW
    end
end


            STOP:
		 begin

                if (scl_phase == 1'b0)
                begin
                    scl_oe = 1'b1;   // SCL LOW
                    sda_oe = 1'b1;   // SDA LOW
                end
                else
                begin
                    scl_oe = 1'b0;   // SCL HIGH
                    sda_oe = 1'b0;   // SDA still LOW
                end

            end

            default:
            begin
                scl_oe = 1'b0;
                sda_oe = 1'b0;
            end

        endcase
    end

endmodule
