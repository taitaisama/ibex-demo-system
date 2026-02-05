`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/29/2026 08:32:25 PM
// Design Name: 
// Module Name: tb_versal
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


module tb_versal;
    

  reg clk_n = 0;
  reg clk_p = 1;
  reg hw_rstn = 0;
  reg sw_rstn = 0;

  // clock
  always #5 clk_n = ~clk_n;
  always #5 clk_p = ~clk_p;

  // DUT
  ps_sim_wrapper dut (
    .sys_clk_n(clk_n),
    .sys_clk_p(clk_p),
    .hw_rstn(hw_rstn),
    .sw_rstn(sw_rstn)
    // connect other ports here
  );

  initial begin
    #400;
    hw_rstn = 1;
    #200;
    sw_rstn = 1;
    #10000;
    $finish;
  end

endmodule
