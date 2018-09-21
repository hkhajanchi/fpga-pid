`timescale 1ns / 1ps

// Recursive Digital PI Implementation in Verilog 

//Methodology
// - FSM to allow sequential processing of data samples from the ADC 
// - Uses an incremental PI form to compute increments to the control output 
// - Clips the integrator portion to a pre-determined voltage to prevent integrator windup 



module PI_Controller(clk,reset_b,adc_in_0,adc_in_1,adc_done,u,pi_done);

    parameter IDLE = 0000; 
    parameter readADC = 0001; 
    parameter computeError = 0002; 
    parameter computeDeltaU = 0003; 
    parameter computeU = 0004; 
    parameter latchDAC = 0005; 

    input clk; 
    input reset_b; 
    input [15:0] adc_in_0; 
    input [15:0] adc_in_1; 
    input adc_done; 
    output reg signed [15:0] u; 
    output reg pi_done; 
    
  //Local Variables 
  wire signed [15:0] error_bus; 
  wire signed [15:0] deltaU_bus; 
  wire signed [15:0] controlOutput_bus; 
  wire signed [15:0] u_out_bus; 
  
  
  reg [3:0] current_state; 
  reg [3:0] next_state; 
  reg signed [15:0] error; 
  reg signed [15:0] error_prev; 
  reg signed [15:0] deltaU; 
  reg signed [15:0] u_prev; 
  
  
 //Module Instantiations 
 
  Error_Calculator u_ErrorCalculator 
  ( 
  .clk(clk),
  .reset_b(reset_b),
  .adc_in_0(adc_in_0),
  .adc_in_1(adc_in_1),
  .error(error_bus)
  ); 
 
 deltaU u_deltaU 
 ( 
 .error(error),
 .errorPrev(error_prev),
 .deltaU(deltaU_bus)
 ); 
 
 control_output u_control_output
 ( 
 .clk(clk), 
 .reset_b(reset_b), 
 .state(current_state), 
 .delta_u(deltaU),
 .u_prev(u_prev),
 .u_out(u_out_bus)
 ); 
   
  //FSM 
  always @ (posedge clk) 
    begin 
        if (!reset_b)
            current_state <= IDLE; 
        else 
            current_state <= next_state; 
    end
    
always @ (posedge clk) 
    begin 
        
        if (!reset_b) 
            next_state <= IDLE; 
        
        else 
            begin 
                    
                 case (current_state)
                 
                 IDLE: if (adc_done) 
                         begin 
                         next_state <= readADC; 
                         end 
                       else 
                         next_state <= IDLE;
                         
                readADC: next_state <= computeError; 
                computeError: next_state <= computeDeltaU; 
                computeDeltaU: next_state <= computeU; 
                computeU: next_state <= latchDAC;
                latchDAC: next_state <= IDLE; 
                default: next_state <= IDLE; 
                
                endcase
           end
     end
     
always @ (posedge clk) 
    begin 
    
        if (!reset_b) 
            begin 
                pi_done <= 0; 
                u <= 0; 
            end  
            
        else  
            begin 
                
                if (current_state == IDLE) 
                   begin 
                   pi_done <= 1; 
                   u <= u; 
                   end 
                else if (current_state == readADC) 
                    begin 
                    pi_done <= 0; 
                    end
                else if (current_state == computeError) 
                    begin 
                    error <= error_bus; 
                    error_prev <= error; 
                    end 
                else if (current_state == computeDeltaU) 
                    begin 
                    deltaU <= deltaU_bus; 
                    end 
                else if (current_state == computeU) 
                    begin 
                    u <= u_out_bus; 
                    u_prev <= u; 
                    end
                else if (current_state <= latchDAC) 
                    begin 
                    pi_done <= 1'b1; 
                    end 
             end    
      end          
                         












endmodule
