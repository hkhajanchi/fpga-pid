`timescale 1ns / 1ps

//Verilog Controller for a SPI-based Digital to Analog Converter 

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



module spi2dac (clk,reset_b,dac_par_in, dac_cs, dac_sclk, dac_mosi); 

    input clk; 
    input reset_b; 
    input [11:0] dac_par_in; 
    output dac_cs; 
    output dac_sclk; 
    output dac_mosi; 


reg dac_cs; 
wire dac_out;

reg clk_1MHZdac; 
reg [5:0] ctrdac; 


parameter TC = 6'd63; 
parameter control_vector = 4'b0000;

//State Parameters
parameter IDLE = 4'd0000; 
parameter SHIFT_OUT = 4'd0001; 
parameter SYNC_DATA = 4'd0002; 
reg tick_dac; 

//Clock Divider Module - Takes the FPGA's 100 MHZ clock and creates a derivative 1.2 MHZ clock to be used for the DAC
always @ (posedge clk) 
    if (!reset_b) 
        begin
        ctrdac <= 0; 
        tick_dac <= 0; 
        clk_1MHZdac <= 0; 
        end
    else
        begin
        ctrdac <= ctrdac - 1'b1; 
        tick_dac <= 0; 
     if (ctrdac == 63) 
        begin 
        tick_dac <= 1'b1; 
        clk_1MHZdac <= ~clk_1MHZdac; 
        end 
    else if (ctrdac == 31)
        begin 
        clk_1MHZdac <= ~clk_1MHZdac;
        end 
  end     
         
assign dac_sclk = clk_1MHZdac; 

//Counter Module

reg parLoad_en;
reg shift_en; 
reg [15:0] shift_reg_dac1; 
reg data_val_out;  
reg [4:0] shift_ctr; 

always @ (posedge clk) 
    if (tick_dac == 1) 
        begin 
            if (parLoad_en == 1) 
                begin 
                shift_ctr <= 4'b0000; 
                shift_reg_dac1 <= {control_vector, dac_par_in}; 
                end 
            else if (shift_en == 1) 
                begin 
                shift_reg_dac1 <= {shift_reg_dac1[14:0], shift_reg_dac1[15]}; 
                shift_ctr <= shift_ctr + 1; 
                end 
         data_val_out <= shift_reg_dac1[15]; 
        end 
 
 assign dac_mosi = shift_reg_dac1[15]; 

 
 //Controller FSM 
reg [4:0] current_state;
reg [4:0] next_state;  
 
 //Synchronous state set
 always @ (posedge clk) 
    if (tick_dac == 1) 
        begin 
            if (!reset_b) 
                current_state <= IDLE; 
            else 
                current_state <= next_state; 
        end 
 
//Unsynchronous Output Generation 

reg dac_done; 
always @ (posedge clk)
begin

if (current_state == IDLE)
    begin 
    shift_en <= 0; 
    dac_done <= 1; 
    dac_cs <= 1; 
    parLoad_en <= 1;             
    end 
else if (current_state == SHIFT_OUT) 
    begin 
    shift_en <= 1; 
    dac_done <= 0; 
    dac_cs <= 0; 
    parLoad_en <= 0; 
    end 
else if (current_state == SYNC_DATA) 
    begin 
    shift_en <= 0; 
    dac_done <= 0; 
    dac_cs <= 1; 
    parLoad_en <= 0; 
    end 
    
end     

always @ (posedge clk) 
    begin 
        if (reset_b) 
            begin
            
                case (current_state)
                
                IDLE :  next_state <= SHIFT_OUT;  
                SHIFT_OUT: if (shift_ctr == 4'hF) 
                               begin 
                               next_state <= SYNC_DATA; 
                               end 
               SYNC_DATA: next_state <= IDLE;
               default : next_state <= IDLE; 
               
               endcase 
           end
   end 



endmodule 
