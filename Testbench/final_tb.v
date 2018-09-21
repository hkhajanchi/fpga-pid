`timescale 1ns / 1ps


//Verilog Testbench that mimics the serial communication of the PMOD AD1 and DA2 
//Meant to emulate the functionality of the PMOD interfaces and the algorithms implemented on the FPGA
module tb1();

reg clk; 
wire adc_cs_out; 
wire adc_sclk; 
wire adc_miso0;  
wire adc_miso1;

wire dac_cs; 
wire dac_sclk; 
wire dac_mosi; 

reg reset_b;
reg [4:0] count1; 
reg [15:0] data_in;
reg [15:0] setpoint_value;
wire [3:0] idx;
wire start; 

top uut ( 
.clk(clk), 
.reset_b(reset_b), 
.adc_miso0 (adc_miso0),
.adc_miso1 (adc_miso1),
.adc_cs_out (adc_cs_out), 
.adc_sclk (adc_sclk),
.dac_cs (dac_cs), 
.dac_sclk (dac_sclk), 
.dac_mosi (dac_mosi)
); 


initial  
forever 
begin 
        clk = 1; 
        #5;
        clk = 0; 
        #5;
end 

initial 
begin 
    
    reset_b = 0; 
    #25 
    reset_b = 1; 
end   
 
always @ (negedge adc_sclk) 
if (adc_cs_out) 
        count1 <= 0;
else 
        count1 <= count1 + 1; 

assign start = ((count1 % 32) == 0);

initial
    begin 
    data_in = 12'b0;
    #20000 
    data_in = 12'd1000; 
    #20000 
    data_in = 12'b010011011001;
    #40000 
    data_in = 12'b100110110010;
    end 
    
initial setpoint_value = 12'b100110110010;


assign idx = (15-count1);
assign adc_miso0 = setpoint_value[idx];
assign adc_miso1 = data_in[idx];        





endmodule
