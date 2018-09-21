`timescale 1ns / 1ps

//SPI-based controller for the PMOD AD1 


//Functionality: 
// - Sends out Chip Select and Serial Clock signals to control the Converter 
// - Reads in 12 bit digital samples and shifts it out serially on the positive edge of the serial clock signal 
// - Finite State Machines to ensure that the controller only sends out samples that are fully read in and in a synchronized manner

//Methodology 
//Uses a FSM to control the DAC 
// IDLE State 
// - The dac_cs signal is set high to pause DAC operations
// - The parLoad_en signal is set high to read in digital samples from the outside modules 
// - The dac_done signal is set high to allow digital samples to be read in 

//SHIFT_OUT state 
// - The controller shifts out bits of the digital signal in a serial manner 
//    - Operates on the positive edge of the serial clock signal, takes roughly 16 SClk signals to send a sample through
// - The parLoad_en and dac_done signals are set low to prevent samples from being read in

//SYNC_DATA 
// - This state acts as a buffer to allow the FFs to latch properly


module spi2adc (clk,reset_b,adc_cs_out,adc_sclk,adc_miso0,adc_miso1,setpoint_data, adc_par_out,adc_done_flag); 

input clk; 
input reset_b;
output reg adc_cs_out; 
output adc_sclk; 
input adc_miso0; 
input adc_miso1;
output adc_done_flag;
output reg [11:0] setpoint_data;
output reg [11:0] adc_par_out; 
 
reg adc_cs; 
     
parameter IDLE = 0000; 
parameter SHIFT_OUT = 0001; 
parameter LATCH = 0002;     



//Generate Serial CLK at 1 MHZ

//reg [11:0] adc_par_out; 
reg clk_1MHZ; 
reg [5:0] ctr; 
parameter TC = 6'd63; 
reg tick; 


always @ (posedge clk) 
    if (!reset_b) 
        begin
        ctr <= TC; 
        tick <= 0; 
        clk_1MHZ <= 0; 
        end
    else
        begin
        ctr <= ctr - 1'b1; 
        tick <= 0; 
     if (ctr == 63) 
        begin 
        tick <= 1'b1; 
        clk_1MHZ <= ~clk_1MHZ; 
        end 
    else if (ctr == 31)
        begin 
        clk_1MHZ <= ~clk_1MHZ; 
        end 
  end            
assign adc_sclk = clk_1MHZ; 

//END Clock Divide 

reg adc_done; 
reg shift_en; 
(*dont_touch = "true"*)reg [4:0] serial_ctr; 
(*dont_touch = "true"*)reg [15:0] shift_reg_adc;
(*dont_touch = "true"*) reg [15:0] shift_reg_adc1; 

always @ (posedge clk) 
            begin 
            
            if (!reset_b)
                begin 
                shift_reg_adc <= 0; 
                shift_reg_adc1 <= 0; 
                setpoint_data <= 0; 
                adc_par_out <= 0; 
                end 
            else 
                begin
                if (tick == 1) 
                    begin
                
                    if  ((shift_en == 1) && (!adc_cs_out))
                            begin
                            shift_reg_adc <= {shift_reg_adc[14:0],adc_miso0}; 
                            shift_reg_adc1 <= {shift_reg_adc1 [14:0],adc_miso1};
                            serial_ctr <= serial_ctr + 1; 
                            end 
                    else if ((adc_done) && (adc_cs_out))
                        begin 
                        setpoint_data <= shift_reg_adc[11:0];
                        adc_par_out <= shift_reg_adc1[11:0]; 
                        serial_ctr <= 4'b000; 
                        end
                    end 
                end 
        end
//FSM 
reg [4:0] current_state; 
reg [4:0] next_state;

always @ (posedge clk) 
    if (!reset_b) 
        current_state <= IDLE; 
    else 
        begin 
            if (tick == 1) 
                current_state <= next_state; 
        end 
  
//Conditions for State Change
always @ (posedge clk) 
    begin 
        if (!reset_b) 
            next_state <= IDLE; 
        
        else 
            begin 
            
                    case (current_state)
                    
                    IDLE :  next_state <= SHIFT_OUT;  
                    SHIFT_OUT: if (serial_ctr == 4'hE) //Corresponds to 16 Sclk cycles 
                                   begin 
                                   next_state <= LATCH; 
                                   end 
                    LATCH: next_state <= IDLE;
                   default : next_state <= IDLE; 
                   endcase
           end 
    end

always @ (posedge clk) //Signal Generation based on State
    begin 
        
        if (!reset_b) 
            begin 
            shift_en <= 0; 
            adc_done <= 1; 
            adc_cs <=1; 
            end 
        
        else 
            begin 
                 begin
                   if (current_state == IDLE)
                       begin 
                       shift_en <= 0; 
                       adc_done <= 1; 
                       adc_cs <= 1;             
                       end 
                   else if (current_state == SHIFT_OUT) 
                       begin 
                       shift_en <= 1; 
                       adc_done <= 0; 
                       adc_cs <= 0; 
                       end 
                   else if (current_state == LATCH) 
                       begin 
                       shift_en <= 0; 
                       adc_done <= 0; 
                       adc_cs <= 1; 
                       end 
               end 
    end
    end

always @ (posedge clk) 
    adc_cs_out <= adc_cs; 

reg adc_done_flag; 

always @ (posedge clk) 
    adc_done_flag <= adc_done; 


endmodule 

