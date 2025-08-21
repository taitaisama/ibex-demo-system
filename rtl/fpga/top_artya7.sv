// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// This is the top level SystemVerilog file that connects the IO on the board to the Ibex Demo System.
module top_artya7 #(
  parameter SRAMInitFile = "/home/ritu/dev/work/ibex-demo-system/sw/c/build/demo/hello_world/demo.hex"
) (
  // These inputs are defined in data/pins_artya7.xdc
  input	       IO_CLK,
  input	       IO_RST_N,
  output [11:0] RGB_LED,
  input [3:0] BTN,
  input [3:0] SW,
  output [3:0] LED
);

  logic clk_sys, rst_sys_n;

   logic dummy;

   localparam int DS = 1;
   // localparam int DELAY = 200000000;

  logic [7:0] dout [4][DS];

   logic [1:0] btc;

   assign btc = (BTN[0] == 1'b1) ? 2'b00 : ((BTN[1] == 1'b1) ? 2'b01 : ((BTN[2] == 1'b1) ? 2'b10 : ((BTN[3] == 1'b1) ? 2'b11 : 2'b00)));

   
   // assign RGB_LED[0] = dout[btc][SW][4];
   // assign RGB_LED[3] = dout[btc][SW][5];
   // assign RGB_LED[6] = dout[btc][SW][6];
   // assign RGB_LED[9] = dout[btc][SW][7];
   
   // assign RGB_LED[1] = 0;
   // assign RGB_LED[2] = 0;
   // assign RGB_LED[4] = 0;
   // assign RGB_LED[5] = 0;
   // assign RGB_LED[7] = 0;
   // assign RGB_LED[8] = 0;
   // assign RGB_LED[10] = 0;
   // assign RGB_LED[11] = 0;

   // assign LED = dout[btc][SW][3:0];
   
  // // Instantiating the Ibex Demo System.
  // ibex_demo_system #(
  //   .GpiWidth     ( 0            ),
  //   .GpoWidth     ( 1            ),
  //   .PwmWidth     ( 0           ),
  //   .SRAMInitFile ( "/home/ritu/dev/work/ibex-demo-system/sw/c/build/demo/hello_world/demo.hex" ),
  //   .DS  (DS)
  // ) u_ibex_demo_system (
  //   //input
  //   .clk_sys_i (clk_sys),
  //   .rst_sys_ni(rst_sys_n),
  //   .gp_i      (),
  //   .uart_rx_i (1'b0),

  //   //output
  //   .gp_o     ({dummy}),
  //   .pwm_o    (),
  //   .uart_tx_o(),

  //   .spi_rx_i (1'b0),
  //   .spi_tx_o (),
  //   .spi_sck_o(),

  //   .debug_out(dout),

  //   .trst_ni(1'b1),
  //   .tms_i  (1'b0),
  //   .tck_i  (1'b0),
  //   .td_i   (1'b0),
  //   .td_o   ()
  // );


  localparam logic [31:0] MEM_SIZE      = 128 * 1024; // 128 KiB 
   
  logic [31:0] ram_out;

   assign dout[0][0] = ram_out[7:0];
   assign dout[1][0] = ram_out[15:8];
   assign dout[2][0] = ram_out[23:16];
   assign dout[3][0] = ram_out[31:24];

   assign RGB_LED[0] = dout[btc][0][4];
   assign RGB_LED[3] = dout[btc][0][5];
   assign RGB_LED[6] = dout[btc][0][6];
   assign RGB_LED[9] = dout[btc][0][7];
   
   assign RGB_LED[1] = 0;
   assign RGB_LED[2] = 0;
   assign RGB_LED[4] = 0;
   assign RGB_LED[5] = 0;
   assign RGB_LED[7] = 0;
   assign RGB_LED[8] = 0;
   assign RGB_LED[10] = 0;
   assign RGB_LED[11] = 0;

   assign LED = dout[btc][0][3:0];
   

  // assign LED[0] = (ram_out == 32'h0040006F);
  // assign LED[3:1] = 3'b111;
  // assign LED = 1'b1;
  
  ram_2p #(
      .Depth       ( MEM_SIZE / 4 ),
      .MemInitFile ( SRAMInitFile )
  ) u_ram (
    .clk_i (clk_sys),
    .rst_ni(rst_sys_n),

    .a_req_i   ('d0),
    .a_we_i    ('d0),
    .a_be_i    ('d0),
    .a_addr_i  ('d0),
    .a_wdata_i ('d0),
    .a_rvalid_o(),
    .a_rdata_o (),

    .b_req_i   (1'b1),
    .b_we_i    (1'b0),
    .b_be_i    (4'b0),
    .b_addr_i  (32'h00100080),
    .b_wdata_i (32'b0),
    .b_rvalid_o(),
    .b_rdata_o (ram_out)
  );


  // Generating the system clock and reset for the FPGA.
  clkgen_xil7series clkgen(
    .IO_CLK,
    .IO_RST_N,
    .clk_sys,
    .rst_sys_n
  );

endmodule
