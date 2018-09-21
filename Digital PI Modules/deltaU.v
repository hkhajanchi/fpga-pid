`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/29/2018 12:51:26 PM
// Design Name: 
// Module Name: deltaU
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


module deltaU(error,errorPrev,deltaU);

    input signed [15:0] error;
    input signed [15:0] errorPrev;  
    output signed [15:0] deltaU; 
    
 parameter KpKi = 3; 
 parameter KiKp = 1; 
 
assign deltaU = (KpKi * error) + (KiKp * errorPrev); 
  
endmodule
