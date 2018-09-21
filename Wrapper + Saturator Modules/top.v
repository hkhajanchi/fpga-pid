`timescale 1ns / 1ps

//Verilog Modules for a functioning PI Controller 
//The algorithm used was derived from a continuous time PI equation discretized using a Bilinear Transform and a sampling rate of roughly 1.2 kHz
//The discrete PI algorithm is shown below 
//u[k] = u[k-1] + (Kp+Ki)*e[k] + (Kp - Ki) * e[k-1]
//The algorithm was converted into velocity form to account for Integrator windup and to prevent massive control outputs 
//deltaU = (Kp+Ki)*e[k] + (Kp - Ki) * e[k-1]
//u[k] = u[k-1] + deltaU 
//The incremental algorithm accounts for the speed of calculations in the FPGA and does not let the recursive portion to overflow

//The overall methodology used was to 
// 1. Read in the samples from the PMOD AD1 Analog-To-Digital Converter
// 2. Zero-pad the samples to convert from 12-bit to 16-bit
// 3. Feed the 16-bit samples to the PI module
// 4. Take the control output from the PI module and run it through a saturator which clips the output at 3723 and 0 (these correspond to threshold voltages for the PMOD DA2 Digital To Analog converter) 
// 5. Feed the saturator output to the PMOD DA2 Digital-to-Analog Converter 

module top(clk,reset_b,adc_cs_out,adc_sclk,adc_miso0,adc_miso1,dac_cs,dac_sclk,dac_mosi);

    input clk; 
    input reset_b; 
    input adc_miso0; 
    input adc_miso1; 
    
    output adc_cs_out;
    output adc_sclk;  
    output dac_cs; 
    output dac_sclk; 
    output dac_mosi; 

    //Local Variables 
    
    reg [15:0] adc_in_0_16bit; 
    reg [15:0] adc_in_1_16bit;
     
    wire [11:0] adc_in_0; 
    wire[11:0] adc_in_1; 
    
    wire pi_done; 
    wire adc_done_flag; 
    wire signed [15:0] control_signal_out; 
    wire [15:0] control_signal_saturated; 
   
   //Module Instantiations 
   
   spi2adc u_spi2adc 
   ( 
   .clk(clk), 
   .reset_b(reset_b), 
   .adc_cs_out(adc_cs_out), 
   .adc_sclk(adc_sclk), 
   .adc_miso0(adc_miso0), 
   .adc_miso1(adc_miso1),
   .adc_done_flag(adc_done_flag),
   .setpoint_data(adc_in_0), 
   .adc_par_out(adc_in_1)
   );
   
   //Zero Pads the A/D samples
   always @ (posedge clk) 
        begin 
        
            if (!reset_b) 
                begin 
                adc_in_0_16bit <= 0; 
                adc_in_1_16bit <= 0; 
                end 
                
            else 
                begin
                
                    if (adc_done_flag)
                    begin 
                        adc_in_0_16bit <= {4'b0,adc_in_0};
                        adc_in_1_16bit <= {4'b0, adc_in_1};
                    end 
                    
                    else 
                    begin
                        adc_in_0_16bit <= adc_in_0_16bit; 
                        adc_in_1_16bit <= adc_in_1_16bit; 
                    end
                      
                end 
        end 
    
  PI_Controller u_pi
  
  ( 
  .clk(clk), 
  .reset_b(reset_b),
  .adc_in_0(adc_in_0_16bit), 
  .adc_in_1(adc_in_1_16bit), 
  .adc_done(adc_done_flag), 
  .pi_done(pi_done),
  .u(control_signal_out)
  );
  
 comparator u_comparator 
 (
 .clk(clk), 
 .reset_b(reset_b), 
 .pi_done(pi_done), 
 .data_in(control_signal_out), 
 .data_out(control_signal_saturated)
);

spi2dac u_spi2dac 
(
.clk(clk), 
.reset_b(reset_b), 
.dac_par_in(control_signal_saturated), 
.dac_cs(dac_cs), 
.dac_sclk(dac_sclk), 
.dac_mosi(dac_mosi)
); 
    





endmodule
