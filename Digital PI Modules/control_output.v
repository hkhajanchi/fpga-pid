`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/31/2018 10:31:19 AM
// Design Name: 
// Module Name: control_output
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module control_output(clk,reset_b,state,delta_u,u_prev,u_out);

    input clk; 
    input reset_b; 
    input [3:0] state; 
    input signed [15:0] delta_u; 
    input signed [15:0] u_prev; 
    output reg signed [15:0] u_out; 
    
    parameter computeU = 0003; 
    parameter integratorClip = 11'd181; 
    
    always @ (posedge clk) 
        begin 
        
            if (!reset_b) 
                u_out <= 0; 
               
               else 
                    begin
                            if (state == computeU) 
                                begin 
                                    if (u_prev <= integratorClip && u_prev >= 0) 
                                        u_out <= delta_u + u_prev; 
                                    else if (u_prev < 0) 
                                        u_out <= delta_u + 0; 
                                    else if (u_prev > integratorClip) 
                                        u_out <= delta_u + integratorClip; 
                                    else 
                                        u_out <= 0; 
                                 end 
                            else 
                                u_out <= u_out; 
                   end 
          end
                             
     
     
     
     
     
     
     
     
     
endmodule
