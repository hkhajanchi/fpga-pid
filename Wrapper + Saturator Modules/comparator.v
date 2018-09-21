`timescale 1ns / 1ps

//Clips the control output to the threshold voltages for the PMOD DA2

module comparator(clk,reset_b,pi_done,data_in,data_out);
    
    input clk; 
    input reset_b; 
    input pi_done; 
    input signed [15:0] data_in; 
    output reg [15:0] data_out;
    
    reg [15:0] data; 
    
    parameter uMAX = 16'd3723; //Cprresponds to roughly 3 Volts in Analog Voltages
    parameter uMIN = 16'd0; //Does not allow negative voltages to pass through
    
    always @(posedge clk) 
        begin 
            if (!reset_b) 
                data <= 0; 
            else 
                begin 
                    if (pi_done) 
                    begin
                    
                        if ((data_in >= uMIN) && (data_in <= uMAX)) 
                            data <= data_in; 
                        else if (data_in > uMAX ) 
                            data <=  uMAX; 
                        else 
                            data <= uMIN; 
                    end
                    
                    else 
                        data <= data;  
                        
                end 
        end 
        
    always @ (posedge clk) 
        data_out <= data; 
        
endmodule