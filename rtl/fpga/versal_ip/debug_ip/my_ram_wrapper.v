`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/18/2025 08:30:31 PM
// Design Name: 
// Module Name: my_ram_wrapper
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


module my_ram_wrapper(
    input  clk,
    input  [12:0] addr,
    output  [31:0] dout
    );
    
    my_ram i_ram (.clk(clk), .addr(addr), .dout(dout));
    
endmodule
